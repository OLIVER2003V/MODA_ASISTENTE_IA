import { Injectable } from '@nestjs/common';
import { Prisma } from 'generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class InAppNotificationService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, type: string, title: string, body: string, data?: Record<string, unknown>) {
    return this.prisma.inAppNotification.create({
      data: { userId, type, title, body, data: data ? (structuredClone(data) as Prisma.InputJsonValue) : undefined },
    });
  }

  async getRecent(userId: string, limit = 30) {
    return this.prisma.inAppNotification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async getUnreadCount(userId: string) {
    return this.prisma.inAppNotification.count({ where: { userId, read: false } });
  }

  async markRead(id: string, userId: string) {
    return this.prisma.inAppNotification.updateMany({
      where: { id, userId },
      data: { read: true },
    });
  }

  async markAllRead(userId: string) {
    return this.prisma.inAppNotification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
  }
}
