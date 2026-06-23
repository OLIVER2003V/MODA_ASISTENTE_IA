import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { CreateUserData } from './dto';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { User } from 'generated/prisma/client';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';
import { SetAvatarDto } from './dto/set-avatar.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { StorageService } from 'src/common/storage/storage.service';
import { InAppNotificationService } from 'src/common/in-app-notification/in-app-notification.service';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly inAppNotif: InAppNotificationService,
  ) {}

  async create(userData: CreateUserData): Promise<User> {
    const hashedPassword = await this.hashPassword(userData.password);

    return this.prisma.user.create({
      data: {
        ...userData,
        password: hashedPassword,
      },
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  async hashPassword(password: string): Promise<string> {
    const salt = 10;
    return bcrypt.hash(password, salt);
  }

  async comparePasswords(
    plainPassword: string,
    hashedPassword: string,
  ): Promise<boolean> {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  async registerFcmToken(
    userId: string,
    registerFcmTokenDto: RegisterFcmTokenDto,
  ): Promise<User> {
    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: registerFcmTokenDto.fcmToken },
    });
  }

  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException(`Usuario ${userId} no encontrado`);
    return this.prisma.user.update({
      where: { id: userId },
      data: { ...dto },
    });
  }

  async uploadProfilePhoto(
    userId: string,
    file: Express.Multer.File,
  ): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException(`Usuario ${userId} no encontrado`);

    // Delete old photo from Cloudinary if exists
    if (user.profilePhoto) {
      const fileName = user.profilePhoto.split('/').pop()?.split('.')[0];
      if (fileName)
        await this.storage
          .deleteFile(`profile-photos/${fileName}`)
          .catch(() => null);
    }

    const uploaded = await this.storage.uploadFile(file, 'profile-photos');

    return this.prisma.user.update({
      where: { id: userId },
      data: { profilePhoto: uploaded.url, avatarStyle: null },
    });
  }

  async removeProfilePhoto(userId: string): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException(`Usuario ${userId} no encontrado`);

    if (user.profilePhoto) {
      const fileName = user.profilePhoto.split('/').pop()?.split('.')[0];
      if (fileName)
        await this.storage
          .deleteFile(`profile-photos/${fileName}`)
          .catch(() => null);
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { profilePhoto: null },
    });
  }

  // ─── Follow ──────────────────────────────────────────────────────────────────

  async getSuggestions(viewerId: string, limit = 20) {
    const following = await this.prisma.follow.findMany({
      where: { followerId: viewerId },
      select: { followingId: true },
    });
    const excludeIds = [...following.map((f) => f.followingId), viewerId];

    const users = await this.prisma.user.findMany({
      where: { id: { notIn: excludeIds }, isActive: true },
      select: {
        id: true,
        name: true,
        profilePhoto: true,
        avatarStyle: true,
        _count: { select: { followers: true, posts: true } },
      },
      take: limit * 3,
    });

    return users
      .map((u) => ({
        id: u.id,
        name: u.name,
        profilePhoto: u.profilePhoto,
        avatarStyle: u.avatarStyle,
        followerCount: u._count.followers,
        postCount: u._count.posts,
        isFollowing: false,
      }))
      .sort((a, b) => b.followerCount - a.followerCount)
      .slice(0, limit);
  }

  async searchUsers(query: string, currentUserId?: string) {
    if (!query.trim()) return [];
    return this.prisma.user.findMany({
      where: {
        AND: [
          { isActive: true },
          currentUserId ? { id: { not: currentUserId } } : {},
          {
            OR: [
              { name: { contains: query, mode: 'insensitive' } },
              { email: { contains: query, mode: 'insensitive' } },
            ],
          },
        ],
      },
      select: {
        id: true,
        name: true,
        profilePhoto: true,
        avatarStyle: true,
        email: true,
      },
      take: 20,
    });
  }

  async follow(followerId: string, followingId: string) {
    if (followerId === followingId)
      throw new ConflictException('No podés seguirte a vos mismo');
    if (!(await this.prisma.user.findUnique({ where: { id: followingId } })))
      throw new NotFoundException('Usuario no encontrado');

    const existing = await this.prisma.follow.findUnique({
      where: { followerId_followingId: { followerId, followingId } },
    });
    if (existing) return existing;

    const result = await this.prisma.follow.create({
      data: { followerId, followingId },
    });

    const followerUser = await this.prisma.user.findUnique({
      where: { id: followerId },
      select: { name: true },
    });
    this.inAppNotif
      .create(
        followingId,
        'follow',
        'Nuevo seguidor',
        `${followerUser?.name ?? 'Alguien'} empezó a seguirte`,
        { followerId },
      )
      .catch(() => null);

    return result;
  }

  async unfollow(followerId: string, followingId: string) {
    const existing = await this.prisma.follow.findUnique({
      where: { followerId_followingId: { followerId, followingId } },
    });
    if (!existing) throw new NotFoundException('No seguís a este usuario');
    await this.prisma.follow.delete({ where: { id: existing.id } });
    return { message: 'Dejaste de seguir al usuario' };
  }

  async getFollowers(userId: string) {
    return this.prisma.follow.findMany({
      where: { followingId: userId },
      orderBy: { createdAt: 'desc' },
      include: {
        follower: {
          select: {
            id: true,
            name: true,
            profilePhoto: true,
            avatarStyle: true,
          },
        },
      },
    });
  }

  async getFollowing(userId: string) {
    return this.prisma.follow.findMany({
      where: { followerId: userId },
      orderBy: { createdAt: 'desc' },
      include: {
        following: {
          select: {
            id: true,
            name: true,
            profilePhoto: true,
            avatarStyle: true,
          },
        },
      },
    });
  }

  async getPublicProfile(targetId: string, viewerId?: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: targetId },
      select: {
        id: true,
        name: true,
        profilePhoto: true,
        avatarStyle: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const [postCount, followerCount, followingCount, isFollowing] =
      await Promise.all([
        this.prisma.post.count({ where: { userId: targetId } }),
        this.prisma.follow.count({ where: { followingId: targetId } }),
        this.prisma.follow.count({ where: { followerId: targetId } }),
        viewerId
          ? this.prisma.follow
              .findUnique({
                where: {
                  followerId_followingId: {
                    followerId: viewerId,
                    followingId: targetId,
                  },
                },
              })
              .then((r) => !!r)
          : Promise.resolve(false),
      ]);

    return { ...user, postCount, followerCount, followingCount, isFollowing };
  }

  async setAvatar(
    userId: string,
    dto: SetAvatarDto,
  ): Promise<User & { avatarUrl: string }> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException(`Usuario ${userId} no encontrado`);

    // Remove real photo if it exists (mutual exclusion)
    if (user.profilePhoto) {
      const fileName = user.profilePhoto.split('/').pop()?.split('.')[0];
      if (fileName)
        await this.storage
          .deleteFile(`profile-photos/${fileName}`)
          .catch(() => null);
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarStyle: dto.style, profilePhoto: null },
    });

    return {
      ...updated,
      avatarUrl: `https://api.dicebear.com/9.x/${dto.style}/svg?seed=${userId}`,
    };
  }
}
