import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { CreateClosetDto } from './dto/create-closet.dto';
import { UpdateClosetDto } from './dto/update-closet.dto';
import { PrismaService } from 'src/common/prisma/prisma.service';

@Injectable()
export class ClosetService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateClosetDto, userId: string) {
    return this.prisma.closet.create({ data: { ...dto, userId } });
  }

  async findByUserId(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const closet = await this.prisma.closet.findFirst({ where: { userId } });
    if (!closet) throw new NotFoundException('No hay closet para este usuario');

    const garments = await this.prisma.garment.findMany({ where: { closetId: closet.id } });
    return { closet, garments };
  }

  findAll() {
    return this.prisma.closet.findMany({
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { garments: true } } },
    });
  }

  async findOne(id: string) {
    const closet = await this.prisma.closet.findUnique({
      where: { id },
      include: { garments: true },
    });
    if (!closet) throw new NotFoundException('Closet no encontrado');
    return closet;
  }

  async update(id: string, dto: UpdateClosetDto, userId: string) {
    const closet = await this.prisma.closet.findUnique({ where: { id } });
    if (!closet) throw new NotFoundException('Closet no encontrado');
    if (closet.userId !== userId) throw new ForbiddenException('No podés modificar este closet');
    return this.prisma.closet.update({ where: { id }, data: dto });
  }

  async remove(id: string, userId: string) {
    const closet = await this.prisma.closet.findUnique({ where: { id } });
    if (!closet) throw new NotFoundException('Closet no encontrado');
    if (closet.userId !== userId) throw new ForbiddenException('No podés eliminar este closet');
    await this.prisma.closet.delete({ where: { id } });
    return { message: 'Closet eliminado' };
  }
}
