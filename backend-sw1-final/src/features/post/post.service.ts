import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService }       from 'src/common/prisma/prisma.service';
import { StorageService }      from 'src/common/storage/storage.service';
import { NotificationsService } from 'src/common/notifications/notifications.service';
import { InAppNotificationService } from 'src/common/in-app-notification/in-app-notification.service';
import { CreatePostDto, CreateCommentDto, PostTypeDto } from './dto/create-post.dto';
import { PostType, ReactionType } from 'generated/prisma/client';

const AUTHOR_SELECT = {
  id: true, name: true, profilePhoto: true, avatarStyle: true,
} as const;

const POST_INCLUDE = {
  user: { select: AUTHOR_SELECT },
  outfit: {
    include: {
      garmentOutfits: {
        include: { garment: true },
        orderBy: { order: 'asc' as const },
      },
    },
  },
} as const;

function extractHashtags(caption?: string | null): string[] {
  if (!caption) return [];
  const matches = caption.match(/#[\wáéíóúüñÁÉÍÓÚÜÑ]+/gi) ?? [];
  return [...new Set(matches.map(t => t.toLowerCase()))];
}

@Injectable()
export class PostService {
  private readonly logger = new Logger(PostService.name);

  constructor(
    private readonly prisma:         PrismaService,
    private readonly storage:        StorageService,
    private readonly notifications:  NotificationsService,
    private readonly inAppNotif:     InAppNotificationService,
  ) {}

  // ─── Upload imagen para post tipo PHOTO ────────────────────────────────────

  async uploadPostImage(file: Express.Multer.File): Promise<{ imageUrl: string }> {
    const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowed.includes(file.mimetype))
      throw new BadRequestException('Solo se permiten imágenes JPG, PNG o WebP');
    if (file.size > 10 * 1024 * 1024)
      throw new BadRequestException('La imagen no puede superar 10 MB');

    const uploaded = await this.storage.uploadFile(file, 'post-images');
    return { imageUrl: uploaded.url };
  }

  // ─── CRUD posts ────────────────────────────────────────────────────────────

  async create(dto: CreatePostDto, userId: string) {
    const type = (dto.postType as PostType) ?? PostType.OUTFIT;

    if (type === PostType.OUTFIT) {
      if (!dto.outfitId) throw new BadRequestException('outfitId es requerido para posts de outfit');
      if (!await this.prisma.outfit.findUnique({ where: { id: dto.outfitId } }))
        throw new NotFoundException('Outfit no encontrado');
    }

    if (type === PostType.PHOTO && !dto.imageUrl)
      throw new BadRequestException('imageUrl es requerido para posts de foto');

    if (type === PostType.TIP && !dto.caption?.trim())
      throw new BadRequestException('caption es requerido para tips');

    const autoTags = extractHashtags(dto.caption);
    const allTags  = [...new Set([...(dto.tags ?? []), ...autoTags])];

    return this.prisma.post.create({
      data: {
        postType:  type,
        outfitId:  dto.outfitId ?? undefined,
        imageUrl:  dto.imageUrl ?? undefined,
        caption:   dto.caption  ?? undefined,
        tags:      allTags,
        userId,
      },
      include: POST_INCLUDE,
    });
  }

  async findAll(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [posts, total] = await Promise.all([
      this.prisma.post.findMany({
        orderBy: { createdAt: 'desc' },
        skip, take: limit,
        include: POST_INCLUDE,
      }),
      this.prisma.post.count(),
    ]);
    return { posts, total, page, limit, hasMore: skip + posts.length < total };
  }

  async findFollowingFeed(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });
    const followingIds = following.map(f => f.followingId);

    if (followingIds.length === 0)
      return { posts: [], total: 0, page, limit, hasMore: false };

    const [posts, total] = await Promise.all([
      this.prisma.post.findMany({
        where: { userId: { in: followingIds } },
        orderBy: { createdAt: 'desc' },
        skip, take: limit,
        include: POST_INCLUDE,
      }),
      this.prisma.post.count({ where: { userId: { in: followingIds } } }),
    ]);
    return { posts, total, page, limit, hasMore: skip + posts.length < total };
  }

  async findByUser(userId: string) {
    return this.prisma.post.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: POST_INCLUDE,
    });
  }

  async findOne(id: string) {
    const post = await this.prisma.post.findUnique({ where: { id }, include: POST_INCLUDE });
    if (!post) throw new NotFoundException('Post no encontrado');
    return post;
  }

  async findByTag(tag: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const normalizedTag = tag.startsWith('#') ? tag.toLowerCase() : `#${tag.toLowerCase()}`;
    const [posts, total] = await Promise.all([
      this.prisma.post.findMany({
        where: { tags: { has: normalizedTag } },
        orderBy: { createdAt: 'desc' },
        skip, take: limit,
        include: POST_INCLUDE,
      }),
      this.prisma.post.count({ where: { tags: { has: normalizedTag } } }),
    ]);
    return { posts, total, page, limit, hasMore: skip + posts.length < total };
  }

  async remove(id: string, userId: string) {
    const post = await this.prisma.post.findUnique({ where: { id } });
    if (!post) throw new NotFoundException('Post no encontrado');
    if (post.userId && post.userId !== userId)
      throw new ForbiddenException('No podés eliminar este post');

    // Borrar imagen de Cloudinary si es post tipo PHOTO
    if (post.imageUrl && post.postType === PostType.PHOTO) {
      const publicId = post.imageUrl.split('/').slice(-2).join('/').split('.')[0];
      await this.storage.deleteFile(publicId).catch(() => null);
    }

    await this.prisma.$transaction([
      this.prisma.comment.deleteMany({ where: { postId: id } }),
      this.prisma.postInteraction.deleteMany({ where: { postId: id } }),
      this.prisma.post.delete({ where: { id } }),
    ]);
    return { message: 'Post eliminado' };
  }

  // ─── Reacciones ────────────────────────────────────────────────────────────

  async react(postId: string, userId: string, reactionType: ReactionType = ReactionType.LIKE) {
    const post = await this.prisma.post.findUnique({ where: { id: postId }, include: { user: true } });
    if (!post) throw new NotFoundException('Post no encontrado');

    const existing = await this.prisma.postInteraction.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      if (existing.reactionType === reactionType) return existing;
      return this.prisma.postInteraction.update({
        where: { id: existing.id },
        data: { reactionType },
        include: { user: { select: AUTHOR_SELECT } },
      });
    }

    const reactingUser = await this.prisma.user.findUnique({ where: { id: userId } });

    const [interaction] = await this.prisma.$transaction([
      this.prisma.postInteraction.create({
        data: { postId, userId, reactionType },
        include: { user: { select: AUTHOR_SELECT } },
      }),
      this.prisma.post.update({ where: { id: postId }, data: { reactionCount: { increment: 1 } } }),
    ]);

    if (post.userId && post.userId !== userId) {
      const REACTION_LABELS: Record<ReactionType, string> = {
        LIKE: 'le gustó', LOVE: 'amó', FIRE: 'le pareció 🔥', WOW: 'quedó 😮 con',
      };
      const label = REACTION_LABELS[reactionType] ?? 'reaccionó a';
      this.inAppNotif.create(
        post.userId, 'reaction',
        'Nueva reacción',
        `${reactingUser?.name ?? 'Alguien'} ${label} tu publicación`,
        { postId, reactionType },
      ).catch(() => null);

      if (post.user?.fcmToken) {
        this.notifications.sendNotification({
          token: post.user.fcmToken,
          title: 'Nueva reacción',
          body: `${reactingUser?.name ?? 'Alguien'} ${label} tu publicación`,
          data: { postId, type: 'reaction' },
        }).catch(e => this.logger.warn(`FCM: ${(e as Error).message}`));
      }
    }
    return interaction;
  }

  async unreact(postId: string, userId: string) {
    const existing = await this.prisma.postInteraction.findUnique({
      where: { userId_postId: { userId, postId } },
    });
    if (!existing) throw new NotFoundException('No habías reaccionado');

    await this.prisma.$transaction([
      this.prisma.postInteraction.delete({ where: { id: existing.id } }),
      this.prisma.post.update({ where: { id: postId }, data: { reactionCount: { decrement: 1 } } }),
    ]);
    return { message: 'Reacción eliminada' };
  }

  async getReactions(postId: string) {
    if (!await this.prisma.post.findUnique({ where: { id: postId } }))
      throw new NotFoundException('Post no encontrado');
    return this.prisma.postInteraction.findMany({
      where: { postId },
      orderBy: { createdAt: 'desc' },
      include: { user: { select: AUTHOR_SELECT } },
    });
  }

  async getUserReactions(userId: string) {
    return this.prisma.postInteraction.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { postId: true, reactionType: true },
    });
  }

  async getReactionSummary(postId: string) {
    const reactions = await this.prisma.postInteraction.groupBy({
      by: ['reactionType'],
      where: { postId },
      _count: { reactionType: true },
    });
    return reactions.map(r => ({ type: r.reactionType, count: r._count.reactionType }));
  }

  // ─── Comentarios ───────────────────────────────────────────────────────────

  async createComment(postId: string, userId: string, dto: CreateCommentDto) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post no encontrado');

    const [comment] = await this.prisma.$transaction([
      this.prisma.comment.create({
        data: { postId, userId, content: dto.content },
        include: { user: { select: AUTHOR_SELECT } },
      }),
      this.prisma.post.update({ where: { id: postId }, data: { commentCount: { increment: 1 } } }),
    ]);

    if (post.userId && post.userId !== userId) {
      const commenter = await this.prisma.user.findUnique({ where: { id: userId }, select: { name: true } });
      this.inAppNotif.create(
        post.userId, 'comment',
        'Nuevo comentario',
        `${commenter?.name ?? 'Alguien'} comentó tu publicación`,
        { postId, commentId: comment.id },
      ).catch(() => null);
    }

    return comment;
  }

  async getComments(postId: string) {
    if (!await this.prisma.post.findUnique({ where: { id: postId } }))
      throw new NotFoundException('Post no encontrado');
    return this.prisma.comment.findMany({
      where: { postId },
      orderBy: { createdAt: 'asc' },
      include: { user: { select: AUTHOR_SELECT } },
    });
  }

  async deleteComment(commentId: string, userId: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comentario no encontrado');
    if (comment.userId !== userId) throw new ForbiddenException('No podés eliminar este comentario');

    await this.prisma.$transaction([
      this.prisma.comment.delete({ where: { id: commentId } }),
      this.prisma.post.update({ where: { id: comment.postId }, data: { commentCount: { decrement: 1 } } }),
    ]);
    return { message: 'Comentario eliminado' };
  }
}
