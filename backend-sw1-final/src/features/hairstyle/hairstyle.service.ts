import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import type { HairstyleModel } from '../../../generated/prisma/models/Hairstyle';
import { AiService } from 'src/features/ai/ai.service';
import { StorageService } from 'src/common/storage/storage.service';
import { PythonAiService } from 'src/common/python/python-ai.service';

@Injectable()
export class HairstyleService {
  private readonly logger = new Logger(HairstyleService.name);

  constructor(
    private readonly prisma:     PrismaService,
    private readonly aiService:  AiService,
    private readonly storage:    StorageService,
    private readonly pythonAi:   PythonAiService,
  ) {}

  // ─── Upload ──────────────────────────────────────────────────────────────────

  async uploadHairstyles(files: Express.Multer.File[], gender?: string) {
    if (!files || files.length === 0) {
      throw new BadRequestException('Debe enviar al menos una imagen');
    }

    const created: HairstyleModel[] = [];

    for (const file of files) {
      // 1. Upload image to GCS
      const uploaded = await this.storage.uploadFile(file, 'hairstyles');

      // 2. Describe with Gemini (text + gender detection)
      const analysis = await this.aiService.describeHairstyle(file.buffer, file.mimetype);

      // 3. Get CLIP embedding from Python service (non-blocking: null if unavailable)
      let embeddingJson: string | null = null;
      try {
        const emb = await this.pythonAi.embedHairstyle(file.buffer, file.mimetype);
        if (emb) embeddingJson = JSON.stringify(emb);
      } catch (err) {
        this.logger.warn(`Skipping CLIP embedding for ${file.originalname}: ${(err as Error).message}`);
      }

      // 4. Persist
      const hairstyle = await this.prisma.hairstyle.create({
        data: {
          description: analysis.description,
          imageUrl:    uploaded.url,
          imagePath:   uploaded.fileName,
          gender:      gender || analysis.gender,
          embedding:   embeddingJson,
        },
      });

      created.push(hairstyle);
    }

    return created;
  }

  // ─── Find all ────────────────────────────────────────────────────────────────

  async findAll() {
    const hairstyles = await this.prisma.hairstyle.findMany({
      orderBy: { createdAt: 'desc' },
    });
    // imageUrl is stored as a permanent Cloudinary URL on upload — no need for extra API calls
    return hairstyles;
  }

  // ─── Favorites ───────────────────────────────────────────────────────────────

  async addFavorite(userId: string, hairstyleId: string) {
    const hairstyle = await this.prisma.hairstyle.findUnique({ where: { id: hairstyleId } });
    if (!hairstyle) throw new BadRequestException('Peinado no encontrado');
    return this.prisma.hairstyleFavorite.upsert({
      where: { userId_hairstyleId: { userId, hairstyleId } },
      create: { userId, hairstyleId },
      update: {},
      include: { hairstyle: true },
    });
  }

  async removeFavorite(userId: string, hairstyleId: string) {
    await this.prisma.hairstyleFavorite.deleteMany({ where: { userId, hairstyleId } });
    return { success: true };
  }

  async getFavorites(userId: string) {
    const favorites = await this.prisma.hairstyleFavorite.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { hairstyle: true },
    });
    return favorites.map(f => ({
      ...f.hairstyle,
      favoriteId: f.id,
      favoritedAt: f.createdAt,
    }));
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  async remove(id: string) {
    const hairstyle = await this.prisma.hairstyle.findUnique({ where: { id } });
    if (!hairstyle) throw new Error('Peinado no encontrado');
    await this.storage.deleteFile(hairstyle.imagePath).catch(() => {});
    await this.prisma.hairstyle.delete({ where: { id } });
    return { success: true };
  }

  // ─── Recommend ───────────────────────────────────────────────────────────────

  async recommendFromFace(faceFile: Express.Multer.File, userId?: string) {
    const allHairstyles = await this.prisma.hairstyle.findMany();

    if (allHairstyles.length === 0) {
      throw new BadRequestException('No hay peinados en el catálogo aún.');
    }

    // Resolve user gender from profile to filter catalog
    const userGender = await this._resolveUserGender(userId);
    this.logger.log(`User gender resolved: ${userGender ?? 'unknown (no filter)'}`);

    // Filter catalog: keep hairstyles matching the user's gender or marked UNISEX / null
    const hairstyles = userGender
      ? allHairstyles.filter(h =>
          !h.gender || h.gender === 'UNISEX' || h.gender === userGender,
        )
      : allHairstyles;

    if (hairstyles.length === 0) {
      // No gender-matched hairstyles → fall back to the full catalog
      this.logger.warn(`No hairstyles match gender ${userGender}. Using full catalog.`);
      allHairstyles.length && hairstyles.push(...allHairstyles);
    }

    // ── Attempt 1: Python microservice ─────────────────────────────────────────
    const pythonResult = await this._tryPythonRecommendation(faceFile, hairstyles, userGender ?? null);
    if (pythonResult) {
      this.logger.log(`[Python] Recommendation succeeded. Face shape: ${pythonResult.faceShape}`);
      return pythonResult.response;
    }

    // ── Attempt 2: Gemini fallback ─────────────────────────────────────────────
    this.logger.warn('Python service unavailable or failed. Falling back to Gemini.');
    return this._geminiRecommendation(faceFile, hairstyles);
  }

  // ─── Try-on ──────────────────────────────────────────────────────────────────

  async tryOnHairstyle(
    faceFile:    Express.Multer.File,
    hairstyleId: string,
    userId?:     string,
  ): Promise<{ tryOnUrl: string; hairstyleId: string }> {
    const hairstyle = await this.prisma.hairstyle.findUnique({ where: { id: hairstyleId } });
    if (!hairstyle) throw new BadRequestException('Peinado no encontrado');

    const apiKey = process.env.REPLICATE_API_KEY;
    if (!apiKey) throw new Error('REPLICATE_API_KEY is not configured');

    const base64Image = `data:${faceFile.mimetype};base64,${faceFile.buffer.toString('base64')}`;

    // Gender = the person being photographed (user profile), not the hairstyle
    const userGender = await this._resolveUserGender(userId);
    const gender     = userGender === 'MALE' ? 'male' : userGender === 'FEMALE' ? 'female' : 'none';

    // Use Gemini to extract exact enum values — regex fallback if Gemini fails
    let haircut: string;
    let hairColor: string;
    try {
      const params = await this.aiService.extractHaircutParams(hairstyle.description ?? '');
      haircut   = params.haircut;
      hairColor = params.hairColor;
      this.logger.log(`[TryOn/Gemini] haircut="${haircut}" color="${hairColor}" gender="${gender}"`);
    } catch (err) {
      this.logger.warn(`[TryOn] Gemini extraction failed, using regex: ${(err as Error).message}`);
      haircut   = this._mapDescriptionToHaircut(hairstyle.description ?? '');
      hairColor = this._mapDescriptionToColor(hairstyle.description ?? '');
      this.logger.log(`[TryOn/Regex] haircut="${haircut}" color="${hairColor}" gender="${gender}"`);
    }

    const replicateUrl = await this._replicateTryOn(apiKey, base64Image, haircut, gender, hairColor);

    // Re-upload to Cloudinary so the URL doesn't expire (Replicate URLs expire in ~24h)
    let tryOnUrl: string = replicateUrl;
    try {
      const dlRes = await fetch(replicateUrl, { signal: AbortSignal.timeout(30_000) });
      if (dlRes.ok) {
        const buffer = Buffer.from(await dlRes.arrayBuffer());
        const uploaded = await this.storage.uploadBuffer(
          buffer,
          `hairstyle-tryon-${Date.now()}.png`,
          'image/png',
          'hairstyle-tryons',
        );
        tryOnUrl = uploaded.url;
        this.logger.log(`[TryOn] Re-uploaded to Cloudinary: ${tryOnUrl}`);
      }
    } catch (err) {
      this.logger.warn(`[TryOn] Re-upload failed, returning Replicate URL: ${(err as Error).message}`);
    }

    return { tryOnUrl, hairstyleId };
  }

  private async _replicateTryOn(
    apiKey:       string,
    imageDataUri: string,
    haircut:      string,
    gender:       string,
    hairColor:    string = 'No change',
  ): Promise<string> {
    const createRes = await fetch(
      'https://api.replicate.com/v1/models/flux-kontext-apps/change-haircut/predictions',
      {
        method:  'POST',
        headers: {
          Authorization:  `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
          Prefer:         'wait=55',
        },
        body: JSON.stringify({
          input: {
            input_image:   imageDataUri,
            haircut,
            hair_color:    hairColor,
            gender,
            output_format: 'png',
            aspect_ratio:  'match_input_image',
          },
        }),
        signal: AbortSignal.timeout(90_000),
      },
    );

    if (!createRes.ok) {
      if (createRes.status === 402) {
        throw new BadRequestException('La cuenta de Replicate no tiene saldo. Recarga en replicate.com/account/billing.');
      }
      const body = await createRes.text();
      throw new Error(`Replicate error ${createRes.status}: ${body}`);
    }

    const prediction = await createRes.json() as {
      status:  string;
      output?: string | string[];
      error?:  string;
      urls?:   { get: string };
    };

    if (prediction.status === 'succeeded' && prediction.output) {
      const out = prediction.output;
      return (Array.isArray(out) ? out[0] : out) as string;
    }

    const pollUrl = prediction.urls?.get;
    if (!pollUrl) throw new Error('Replicate did not return a polling URL');

    for (let i = 0; i < 30; i++) {
      await new Promise<void>(r => setTimeout(r, 2_000));
      const poll = await fetch(pollUrl, { headers: { Authorization: `Bearer ${apiKey}` } });
      if (!poll.ok) continue;
      const p = await poll.json() as typeof prediction;
      if (p.status === 'succeeded' && p.output) {
        const out = p.output;
        return (Array.isArray(out) ? out[0] : out) as string;
      }
      if (p.status === 'failed' || p.status === 'canceled') {
        throw new Error(`Replicate prediction ${p.status}: ${p.error ?? ''}`);
      }
    }
    throw new Error('Replicate try-on timed out');
  }

  /** Map a Spanish/English hairstyle description to a Replicate change-haircut enum value. */
  private _mapDescriptionToHaircut(description: string): string {
    const d = description.toLowerCase();
    const has = (...words: string[]) => words.some(w => d.includes(w));

    // ── Compound rules (most specific first) ─────────────────────────────────
    if (has('fade', 'degradado') && has('brillante', 'gomina', 'bien peinado', 'liso'))
      return 'Slicked Back';
    if (has('fade', 'degradado') && has('volumen', 'cresta'))
      return 'Faux Hawk';
    if (has('mohawk') && has('fade', 'degradado'))
      return 'Mohawk Fade';
    if (has('rizado', 'curly', 'crespo') && has('largo', 'long'))
      return 'Curly';
    if (has('ondulado', 'wavy') && has('largo', 'long'))
      return 'Wavy';

    // ── Specific named cuts ───────────────────────────────────────────────────
    if (has('pixie'))                                         return 'Pixie Cut';
    if (has('faux hawk', 'fohawk'))                          return 'Faux Hawk';
    if (has('mohicano', 'mohawk', 'cresta'))                 return 'Mohawk';
    if (has('undercut'))                                     return 'Undercut';
    if (has('crew cut', 'militar corto', 'buzz cut'))        return 'Crew Cut';
    if (has('slicked back', 'hacia atrás', 'peinado atrás')) return 'Slicked Back';
    if (has('side part', 'raya lateral', 'raya al lado'))    return 'Side-Parted';
    if (has('center part', 'raya al centro'))                return 'Center-Parted';
    if (has('flequillo lateral', 'side-swept bang'))         return 'Side-Swept Bangs';
    if (has('flequillo', 'bang'))                            return 'Blunt Bangs';

    // ── Bob family ────────────────────────────────────────────────────────────
    if (has('angled bob', 'bob asimétrico'))    return 'Angled Bob';
    if (has('inverted bob', 'bob invertido'))   return 'Inverted Bob';
    if (has('lob', 'long bob', 'bob largo'))    return 'Lob';
    if (has('bob'))                             return 'Bob';

    // ── Braid family ──────────────────────────────────────────────────────────
    if (has('french braid', 'trenza francesa'))          return 'French Braid';
    if (has('dutch braid', 'trenza holandesa'))          return 'Dutch Braid';
    if (has('fishtail braid', 'trenza espiga'))          return 'Fishtail Braid';
    if (has('box braid'))                                return 'Box Braids';
    if (has('cornrow', 'trenzas africanas'))             return 'Cornrows';
    if (has('trenza', 'braid'))                          return 'French Braid';

    // ── Bun / updo ────────────────────────────────────────────────────────────
    if (has('top knot', 'moño alto'))           return 'Top Knot';
    if (has('messy bun', 'moño despeinado'))    return 'Messy Bun';
    if (has('chignon'))                         return 'Chignon';
    if (has('moño', 'bun'))                     return 'Messy Bun';
    if (has('french twist'))                    return 'French Twist';
    if (has('updo', 'recogido'))                return 'Updo';

    // ── Ponytail ──────────────────────────────────────────────────────────────
    if (has('high ponytail', 'coleta alta'))       return 'High Ponytail';
    if (has('low ponytail', 'coleta baja'))        return 'Low Ponytail';
    if (has('coleta', 'ponytail', 'cola de caballo')) return 'High Ponytail';

    // ── Wave / texture ────────────────────────────────────────────────────────
    if (has('hollywood wave'))   return 'Hollywood Waves';
    if (has('glamorous wave'))   return 'Glamorous Waves';
    if (has('soft wave'))        return 'Soft Waves';
    if (has('finger wave'))      return 'Finger Waves';
    if (has('tousled', 'efecto despeinado')) return 'Tousled';
    if (has('feathered'))        return 'Feathered';
    if (has('shag'))             return 'Shag';
    if (has('ombré', 'ombre', 'balayage')) return 'Ombré';
    if (has('razor cut'))        return 'Razor Cut';
    if (has('choppy'))           return 'Choppy Layers';
    if (has('perm', 'permanente')) return 'Perm';
    if (has('dreadlock', 'rasta')) return 'Dreadlocks';

    // ── Texture primitives ────────────────────────────────────────────────────
    if (has('rizado', 'rizo', 'curly', 'crespo')) return 'Curly';
    if (has('ondulado', 'ondas', 'wavy'))          return 'Wavy';
    if (has('liso', 'alisado', 'straight'))        return 'Straight';

    // ── Broad: fade / layers ──────────────────────────────────────────────────
    if (has('fade', 'degradado')) return 'Undercut';
    if (has('capas', 'layer'))    return 'Layered';

    return 'Layered';
  }

  /** Extract hair color from description to a Replicate hair_color enum value. */
  private _mapDescriptionToColor(description: string): string {
    const d = description.toLowerCase();
    if (/negro|black|azabache|jet black/.test(d))             return 'Jet Black';
    if (/castaño oscuro|dark brown|marrón oscuro/.test(d))    return 'Dark Brown';
    if (/castaño|brunette|marrón|café|chocolate|chestnut/.test(d)) return 'Chestnut';
    if (/caoba|mahogany/.test(d))                             return 'Mahogany';
    if (/cobrizo|copper|cobre/.test(d))                       return 'Copper';
    if (/castaño claro|medium brown/.test(d))                 return 'Medium Brown';
    if (/rubio oscuro|dark blonde|castaño muy claro/.test(d)) return 'Ash Blonde';
    if (/miel|honey blonde/.test(d))                          return 'Honey Blonde';
    if (/dorado|golden blonde/.test(d))                       return 'Golden Blonde';
    if (/rubio|blonde/.test(d))                               return 'Blonde';
    if (/pelirrojo|rojizo|auburn/.test(d))                    return 'Auburn';
    if (/\brojo\b|\bred\b/.test(d))                           return 'Red';
    if (/borgoña|burgundy|vino/.test(d))                      return 'Burgundy';
    if (/rosa|rose gold/.test(d))                             return 'Rose Gold';
    if (/gris|gray|grey|cano|plateado|silver/.test(d))        return 'Silver';
    if (/blanco|white/.test(d))                               return 'White';
    if (/platino|platinum/.test(d))                           return 'Platinum Blonde';
    if (/rubio ceniza|ash blonde/.test(d))                    return 'Ash Blonde';
    if (/ceniza|ash brown/.test(d))                           return 'Ash Brown';
    if (/oscuro|dark/.test(d))                                return 'Dark Brown';
    if (/claro|light brown/.test(d))                          return 'Light Brown';
    return 'Dark Brown'; // most catalog hairstyles are dark
  }

  /** Map any gender string to 'MALE' | 'FEMALE' | null */
  private async _resolveUserGender(userId?: string): Promise<string | null> {
    if (!userId) return null;
    try {
      const attr = await this.prisma.userAttribute.findUnique({ where: { userId } });
      if (!attr?.gender) return null;
      const g = attr.gender.toLowerCase();
      if (['male', 'masculino', 'hombre', 'm', 'masc'].some(v => g.includes(v))) return 'MALE';
      if (['female', 'femenino', 'mujer', 'f', 'fem'].some(v => g.includes(v))) return 'FEMALE';
      return null;
    } catch {
      return null;
    }
  }

  // ── Private: Python path ─────────────────────────────────────────────────────

  private async _tryPythonRecommendation(
    faceFile:   Express.Multer.File,
    hairstyles: HairstyleModel[],
    userGender?: string | null,
  ) {
    try {
      // Build catalog payload for Python
      const catalog = hairstyles.map(h => ({
        id:        h.id,
        embedding: h.embedding ?? null,
        imageUrl:  h.embedding ? null : (h.imageUrl ?? null),
        gender:    h.gender ?? null,
      }));

      const result = await this.pythonAi.recommendHairstyles(
        faceFile.buffer,
        faceFile.mimetype,
        catalog,
        userGender,
      );

      if (!result || result.ranked.length === 0) return null;

      // Map ranked IDs back to DB records
      const rankMap = new Map(result.ranked.map((r) => [r.id, r]));
      const sortedHairstyles = [...hairstyles].sort((a, b) => {
        const ra = rankMap.get(a.id)?.rank ?? 9999;
        const rb = rankMap.get(b.id)?.rank ?? 9999;
        return ra - rb;
      });

      const recommended = sortedHairstyles[0];

      const recUrl = recommended.imageUrl ?? '';
      const catalogWithUrls = sortedHairstyles.map(h => ({ ...h, imageUrl: h.imageUrl ?? '' }));

      // Generate explanation text via Gemini (best-effort; non-critical)
      let explanation = result.face_shape_note ?? '';
      try {
        const geminiResult = await this.aiService.recommendHairstyle(
          faceFile.buffer,
          faceFile.mimetype,
          [{ id: recommended.id, description: recommended.description }],
        );
        if (geminiResult.explanation) explanation = geminiResult.explanation;
      } catch {
        // If Gemini is down, keep the face shape note as explanation
      }

      return {
        faceShape: result.face_shape,
        response: {
          recommended: { ...recommended, imageUrl: recUrl },
          explanation,
          catalog: catalogWithUrls,
          meta: {
            source:          'python',
            face_shape:      result.face_shape,
            face_shape_note: result.face_shape_note,
            face_detected:   result.detected,
            ideal_query:     result.ideal_query,
          },
        },
      };
    } catch (err) {
      this.logger.warn(`Python recommendation path failed: ${(err as Error).message}`);
      return null;
    }
  }

  // ── Private: Gemini fallback ──────────────────────────────────────────────────

  private async _geminiRecommendation(
    faceFile:   Express.Multer.File,
    hairstyles: HairstyleModel[],
  ) {
    const result = await this.aiService.recommendHairstyle(
      faceFile.buffer,
      faceFile.mimetype,
      hairstyles.map((h) => ({ id: h.id, description: h.description })),
    );

    const recommended = hairstyles.find((h) => h.id === result.hairstyleId) ?? hairstyles[0];

    return {
      recommended: { ...recommended, imageUrl: recommended.imageUrl ?? '' },
      explanation: result.explanation,
      catalog:     hairstyles.map(h => ({ ...h, imageUrl: h.imageUrl ?? '' })),
      meta: { source: 'gemini' },
    };
  }
}
