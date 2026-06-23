import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { UpdateOutfitDto } from './dto/update-outfit.dto';
import { AiService } from 'src/features/ai/ai.service';
import { StorageService } from 'src/common/storage/storage.service';

const OUTFIT_INCLUDE = {
  garmentOutfits: {
    include: { garment: true },
    orderBy: { order: 'asc' as const },
  },
} as const;

@Injectable()
export class OutfitService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly aiService: AiService,
    private readonly storage: StorageService,
  ) {}

  findByUserId(userId: string) {
    return this.prisma.outfit.findMany({
      where: {
        garmentOutfits: {
          some: { garment: { closet: { userId } } },
        },
      },
      include: OUTFIT_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const outfit = await this.prisma.outfit.findUnique({
      where: { id },
      include: OUTFIT_INCLUDE,
    });
    if (!outfit)
      throw new NotFoundException(`Outfit con ID ${id} no encontrado`);
    return outfit;
  }

  private async assertOwner(id: string, userId: string) {
    const outfit = await this.prisma.outfit.findUnique({
      where: { id },
      include: {
        garmentOutfits: {
          include: {
            garment: { include: { closet: { select: { userId: true } } } },
          },
        },
      },
    });
    if (!outfit)
      throw new NotFoundException(`Outfit con ID ${id} no encontrado`);
    const owned = outfit.garmentOutfits.some(
      (go) => go.garment.closet.userId === userId,
    );
    if (!owned) throw new ForbiddenException('No podés modificar este outfit');
    return outfit;
  }

  async update(id: string, dto: UpdateOutfitDto, userId: string) {
    await this.assertOwner(id, userId);
    return this.prisma.outfit.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
      },
    });
  }

  async remove(id: string, userId: string) {
    await this.assertOwner(id, userId);
    return this.prisma.outfit.delete({ where: { id } });
  }

  async generateTryOn(
    outfitId: string,
    userId: string,
  ): Promise<{ tryOnImageUrl: string }> {
    const outfit = await this.prisma.outfit.findUnique({
      where: { id: outfitId },
      include: {
        garmentOutfits: {
          include: {
            garment: { include: { closet: { select: { userId: true } } } },
          },
          orderBy: { order: 'asc' },
        },
      },
    });
    if (!outfit)
      throw new NotFoundException(`Outfit ${outfitId} no encontrado`);

    const owned = outfit.garmentOutfits.some(
      (go) => go.garment.closet.userId === userId,
    );
    if (!owned) throw new ForbiddenException('No tenés acceso a este outfit');

    // Usar imagen cacheada si existe
    if (outfit.tryOnImageUrl) {
      return { tryOnImageUrl: outfit.tryOnImageUrl };
    }

    const userAttr = await this.prisma.userAttribute.findUnique({
      where: { userId },
    });

    // Requerir foto de cuerpo — sin ella no podemos preservar el rostro y evitamos
    // llamadas extra a Replicate que consumen cuota y generan rate-limit 429.
    if (!userAttr?.bodyPhotoPath) {
      throw new BadRequestException('NO_BODY_PHOTO');
    }

    let bodyPhotoUrl: string | null = null;
    try {
      bodyPhotoUrl = await this.storage.getSignedUrl(userAttr.bodyPhotoPath);
    } catch {
      /* ignorar */
    }
    if (!bodyPhotoUrl) throw new BadRequestException('NO_BODY_PHOTO');

    const bflUrl = await this.aiService.generateOutfitTryOn(
      outfit,
      userAttr,
      bodyPhotoUrl,
    );

    // Replicate output URLs caducan en 24h — descargar y subir a Cloudinary para caché permanente
    let tryOnImageUrl = bflUrl;
    try {
      const imgRes = await fetch(bflUrl, {
        signal: AbortSignal.timeout(30_000),
      });
      if (imgRes.ok) {
        const imgBuffer = Buffer.from(await imgRes.arrayBuffer());
        const uploaded = await this.storage.uploadBuffer(
          imgBuffer,
          'try-on.jpg',
          'image/jpeg',
          'try-on',
        );
        tryOnImageUrl = uploaded.url;
        console.log(
          '[TryOn] Re-subido a Cloudinary:',
          tryOnImageUrl.slice(0, 60),
        );
      }
    } catch (e) {
      console.warn(
        '[TryOn] No se pudo re-subir a Cloudinary, usando URL temporal:',
        (e as Error).message,
      );
    }

    await this.prisma.outfit.update({
      where: { id: outfitId },
      data: { tryOnImageUrl },
    });

    return { tryOnImageUrl };
  }

  async regenerateTryOn(
    outfitId: string,
    userId: string,
  ): Promise<{ tryOnImageUrl: string }> {
    await this.prisma.outfit.update({
      where: { id: outfitId },
      data: { tryOnImageUrl: null },
    });
    return this.generateTryOn(outfitId, userId);
  }

  async createManual(name: string, garmentIds: string[], userId: string) {
    // Verify all garments belong to the requesting user
    const garments = await this.prisma.garment.findMany({
      where: { id: { in: garmentIds } },
      include: { closet: { select: { userId: true } } },
    });
    const allOwned = garments.every((g) => g.closet.userId === userId);
    if (!allOwned)
      throw new ForbiddenException('Algunas prendas no te pertenecen');

    return this.prisma.outfit.create({
      data: {
        name,
        score: 0,
        garmentOutfits: {
          create: garmentIds.map((garmentId, index) => ({
            garmentId,
            order: index,
          })),
        },
      },
      include: OUTFIT_INCLUDE,
    });
  }
}
