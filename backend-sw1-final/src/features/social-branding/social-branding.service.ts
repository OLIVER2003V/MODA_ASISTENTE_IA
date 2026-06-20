import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { AiService } from 'src/features/ai/ai.service';
import { SocialBrandingDto } from './dto';
import type {
  SocialBrandingResponse,
  UserStyleProfile,
  CaptionSet,
  CalendarDay,
} from './types/social-branding.types';

const BEST_TIMES: Record<string, { mejores: string[]; evitar: string }> = {
  linkedin: {
    mejores: ['Martes a jueves 8–10hs', 'Todos los días 12–13hs', 'Martes a jueves 17–18hs'],
    evitar:  'Fines de semana y horarios nocturnos',
  },
  instagram: {
    mejores: ['Lunes a viernes 9–11hs', 'Lunes a viernes 14–15hs', 'Sábados 10–12hs'],
    evitar:  'Domingos por la mañana y días festivos antes de las 10hs',
  },
  tiktok: {
    mejores: ['Martes a viernes 7–9hs', 'Martes a viernes 19–21hs', 'Domingos 9–11hs'],
    evitar:  'Lunes temprano y entre 13–18hs (horario de menor engagement)',
  },
  facebook: {
    mejores: ['Miércoles a viernes 9–11hs', 'Miércoles a viernes 13hs', 'Jueves 20–21hs'],
    evitar:  'Domingos y horario nocturno después de las 22hs',
  },
};

const HEX_REGEX = /^#[0-9A-Fa-f]{6}$/;
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

@Injectable()
export class SocialBrandingService {
  private readonly logger = new Logger(SocialBrandingService.name);
  private readonly cache = new Map<string, { data: SocialBrandingResponse; expiresAt: number }>();

  constructor(
    private readonly prisma:    PrismaService,
    private readonly aiService: AiService,
  ) {}

  async getRecommendations(userId: string, dto: SocialBrandingDto): Promise<SocialBrandingResponse> {
    const { network, refresh } = dto;
    const cacheKey = `${userId}:${network}`;

    if (refresh) {
      this.cache.delete(cacheKey);
    } else {
      const cached = this.getCached(cacheKey);
      if (cached) {
        this.logger.log(`Cache hit: ${cacheKey}`);
        return cached;
      }
    }

    const { profile, hasProfile } = await this.buildUserProfile(userId);

    this.logger.log(`Generating social branding — userId=${userId} network=${network} hasProfile=${hasProfile}`);
    const aiResult = await this.aiService.generateSocialBranding(profile, network);

    const result: SocialBrandingResponse = {
      network,
      hasProfile,
      imagen: {
        titulo:   this.safeStr(aiResult['imagen']?.['titulo']),
        paleta:   this.sanitizePalette(aiResult['imagen']?.['paleta']),
        keywords: this.safeStrArray(aiResult['imagen']?.['keywords']),
        tips:     this.safeStrArray(aiResult['imagen']?.['tips']),
      },
      contenido: {
        tipos:      this.safeStrArray(aiResult['contenido']?.['tipos']),
        frecuencia: this.safeStr(aiResult['contenido']?.['frecuencia']),
        ideas:      this.safeStrArray(aiResult['contenido']?.['ideas']),
      },
      horarios: BEST_TIMES[network] ?? { mejores: [], evitar: '' },
      hashtags: this.safeStrArray(aiResult['hashtags']),
      tono: {
        titulo:      this.safeStr(aiResult['tono']?.['titulo']),
        descripcion: this.safeStr(aiResult['tono']?.['descripcion']),
        tips:        this.safeStrArray(aiResult['tono']?.['tips']),
      },
      captionTemplates: this.parseCaptionTemplates(aiResult['captionTemplates']),
      contentCalendar:  this.parseCalendar(aiResult['contentCalendar']),
      trendingSearches: this.safeStrArray(aiResult['trendingSearches']),
      profileChecklist: this.safeStrArray(aiResult['profileChecklist']),
    };

    this.setCached(cacheKey, result);
    return result;
  }

  // ─── Cache helpers ──────────────────────────────────────────────────────────

  private getCached(key: string): SocialBrandingResponse | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    return entry.data;
  }

  private setCached(key: string, data: SocialBrandingResponse): void {
    this.cache.set(key, { data, expiresAt: Date.now() + CACHE_TTL_MS });
  }

  // ─── Sanitizers ─────────────────────────────────────────────────────────────

  private safeStr(val: unknown): string {
    return typeof val === 'string' ? val.trim() : '';
  }

  private safeStrArray(val: unknown): string[] {
    if (!Array.isArray(val)) return [];
    return val
      .filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
      .map(s => s.trim());
  }

  private sanitizePalette(val: unknown): string[] {
    if (!Array.isArray(val)) return [];
    return val
      .filter((c): c is string => typeof c === 'string')
      .map(c => {
        const s = c.trim();
        if (HEX_REGEX.test(s)) return s;
        const withHash = `#${s}`;
        if (HEX_REGEX.test(withHash)) return withHash;
        return null;
      })
      .filter((c): c is string => c !== null)
      .slice(0, 3);
  }

  // ─── Profile builder ─────────────────────────────────────────────────────────

  private async buildUserProfile(
    userId: string,
  ): Promise<{ profile: UserStyleProfile; hasProfile: boolean }> {
    try {
      const attr = await this.prisma.userAttribute.findUnique({ where: { userId } });
      if (!attr) return { profile: this.emptyProfile(), hasProfile: false };

      const profile: UserStyleProfile = {
        styles:      attr.preferredStyles ?? [],
        colors:      attr.favoriteColors  ?? [],
        avoidColors: attr.avoidColors     ?? [],
        gender:      attr.gender     ?? null,
        age:         attr.age        ?? null,
        profession:  attr.profession ?? null,
        bodyType:    attr.bodyType   ?? null,
        skinTone:    attr.skinTone   ?? null,
      };

      const hasProfile =
        profile.styles.length > 0 ||
        profile.colors.length > 0 ||
        !!profile.profession;

      return { profile, hasProfile };
    } catch {
      return { profile: this.emptyProfile(), hasProfile: false };
    }
  }

  private emptyProfile(): UserStyleProfile {
    return {
      styles: [], colors: [], avoidColors: [],
      gender: null, age: null, profession: null,
      bodyType: null, skinTone: null,
    };
  }

  private parseCaptionTemplates(val: unknown): CaptionSet[] {
    if (!Array.isArray(val)) return [];
    return val
      .filter((item): item is Record<string, unknown> => typeof item === 'object' && item !== null)
      .map(item => ({
        idea:  this.safeStr(item['idea']),
        corta: this.safeStr(item['corta']),
        media: this.safeStr(item['media']),
        larga: this.safeStr(item['larga']),
      }))
      .filter(c => c.idea.length > 0);
  }

  private parseCalendar(val: unknown): CalendarDay[] {
    const validDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const validTypes = ['OUTFIT', 'PHOTO', 'TIP', 'REST'];

    if (!Array.isArray(val)) return [];
    return val
      .filter((item): item is Record<string, unknown> => typeof item === 'object' && item !== null)
      .map(item => ({
        day:  this.safeStr(item['day']),
        type: this.safeStr(item['type']).toUpperCase(),
        hour: this.safeStr(item['hour']),
        idea: this.safeStr(item['idea']),
      }))
      .filter(d => validDays.includes(d.day))
      .map(d => ({ ...d, type: validTypes.includes(d.type) ? d.type : 'REST' }));
  }
}
