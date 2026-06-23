import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CreateUserAttributeDto } from './dto/create-user-attribute.dto';
import { UpdateUserAttributeDto } from './dto/update-user-attribute.dto';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { StorageService } from 'src/common/storage/storage.service';

@Injectable()
export class UserAttributeService {
  private readonly logger = new Logger(UserAttributeService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {
    this.logger.log('UserAttributeService initialized');
  }

  create({ userId, ...rest }: CreateUserAttributeDto) {
    return this.prisma.userAttribute.create({
      data: { ...rest, user: { connect: { id: userId } } },
    });
  }

  // Devuelve los atributos del usuario, o null si todavía no los completó
  async findByUserId(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException(`Usuario ${userId} no encontrado`);

    const attrs = await this.prisma.userAttribute.findUnique({
      where: { userId },
    });
    return attrs ?? null;
  }

  findAll() {
    return this.prisma.userAttribute.findMany();
  }

  async findOne(id: string) {
    const attr = await this.prisma.userAttribute.findUnique({ where: { id } });
    if (!attr) throw new NotFoundException(`Atributo ${id} no encontrado`);
    return attr;
  }

  update(id: string, { userId: _userId, ...data }: UpdateUserAttributeDto) {
    return this.prisma.userAttribute.update({
      where: { id },
      data,
    });
  }

  remove(id: string) {
    return this.prisma.userAttribute.delete({ where: { id } });
  }

  async uploadBodyPhoto(userId: string, file: Express.Multer.File) {
    const userAttr = await this.prisma.userAttribute.findUnique({
      where: { userId },
    });
    if (!userAttr)
      throw new NotFoundException(
        `Atributos del usuario ${userId} no encontrados`,
      );

    // Eliminar foto anterior si existe
    if (userAttr.bodyPhotoPath) {
      try {
        await this.storage.deleteFile(userAttr.bodyPhotoPath);
      } catch {
        /* ignorar si no existe */
      }
    }

    const uploaded = await this.storage.uploadFile(file, 'body-photos');
    await this.prisma.userAttribute.update({
      where: { userId },
      data: { bodyPhotoPath: uploaded.fileName, bodyPhotoUrl: uploaded.url },
    });

    return { bodyPhotoUrl: uploaded.url };
  }

  async getBodyPhotoUrl(userId: string): Promise<string | null> {
    const userAttr = await this.prisma.userAttribute.findUnique({
      where: { userId },
    });
    if (!userAttr) return null;
    // Return stored URL directly — avoids Cloudinary management API rate limits
    return userAttr.bodyPhotoUrl ?? null;
  }
}
