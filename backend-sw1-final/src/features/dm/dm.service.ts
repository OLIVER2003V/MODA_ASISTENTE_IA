import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { InAppNotificationService } from 'src/common/in-app-notification/in-app-notification.service';
import { NotificationsService } from 'src/common/notifications/notifications.service';

const PARTICIPANT_SELECT = {
  id: true,
  name: true,
  profilePhoto: true,
  avatarStyle: true,
} as const;

@Injectable()
export class DmService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notif: InAppNotificationService,
    private readonly push: NotificationsService,
  ) {}

  private sortedPair(a: string, b: string): [string, string] {
    return a < b ? [a, b] : [b, a];
  }

  async getOrCreate(requesterId: string, targetId: string) {
    if (requesterId === targetId)
      throw new BadRequestException('No podés enviarte mensajes a vos mismo');
    if (!(await this.prisma.user.findUnique({ where: { id: targetId } })))
      throw new NotFoundException('Usuario no encontrado');

    const [p1, p2] = this.sortedPair(requesterId, targetId);

    return this.prisma.directConversation.upsert({
      where: {
        participant1Id_participant2Id: {
          participant1Id: p1,
          participant2Id: p2,
        },
      },
      create: { participant1Id: p1, participant2Id: p2 },
      update: {},
      include: {
        participant1: { select: PARTICIPANT_SELECT },
        participant2: { select: PARTICIPANT_SELECT },
      },
    });
  }

  async getConversations(userId: string) {
    const convs = await this.prisma.directConversation.findMany({
      where: { OR: [{ participant1Id: userId }, { participant2Id: userId }] },
      orderBy: { lastMessageAt: 'desc' },
      include: {
        participant1: { select: PARTICIPANT_SELECT },
        participant2: { select: PARTICIPANT_SELECT },
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
    });

    return Promise.all(
      convs.map(async (conv) => {
        const unread = await this.prisma.directMessage.count({
          where: {
            conversationId: conv.id,
            senderId: { not: userId },
            read: false,
          },
        });
        const other =
          conv.participant1Id === userId
            ? conv.participant2
            : conv.participant1;
        return { ...conv, other, unreadCount: unread };
      }),
    );
  }

  async getMessages(conversationId: string, userId: string) {
    const conv = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
    });
    if (!conv) throw new NotFoundException('Conversación no encontrada');
    if (conv.participant1Id !== userId && conv.participant2Id !== userId)
      throw new ForbiddenException('No tenés acceso a esta conversación');

    await this.prisma.directMessage.updateMany({
      where: { conversationId, senderId: { not: userId }, read: false },
      data: { read: true },
    });

    return this.prisma.directMessage.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      include: { sender: { select: PARTICIPANT_SELECT } },
    });
  }

  async sendMessage(conversationId: string, senderId: string, content: string) {
    const conv = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
    });
    if (!conv) throw new NotFoundException('Conversación no encontrada');
    if (conv.participant1Id !== senderId && conv.participant2Id !== senderId)
      throw new ForbiddenException('No tenés acceso a esta conversación');

    const [msg] = await this.prisma.$transaction([
      this.prisma.directMessage.create({
        data: { conversationId, senderId, content },
        include: { sender: { select: PARTICIPANT_SELECT } },
      }),
      this.prisma.directConversation.update({
        where: { id: conversationId },
        data: { lastMessageAt: new Date() },
      }),
    ]);

    const recipientId =
      conv.participant1Id === senderId
        ? conv.participant2Id
        : conv.participant1Id;
    const sender = await this.prisma.user.findUnique({
      where: { id: senderId },
      select: { name: true },
    });

    const preview = content.length > 60 ? content.slice(0, 60) + '…' : content;
    const senderName = sender?.name ?? 'alguien';

    this.notif
      .create(
        recipientId,
        'message',
        `Nuevo mensaje de ${senderName}`,
        preview,
        { conversationId, senderId },
      )
      .catch(() => null);

    // Push notification
    const recipient = await this.prisma.user.findUnique({
      where: { id: recipientId },
      select: { fcmToken: true },
    });
    if (recipient?.fcmToken) {
      this.push
        .sendNotification({
          token: recipient.fcmToken,
          title: `💬 ${senderName}`,
          body: preview,
          data: { type: 'dm', conversationId },
        })
        .catch(() => null);
    }

    return msg;
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.directMessage.count({
      where: {
        senderId: { not: userId },
        read: false,
        conversation: {
          OR: [{ participant1Id: userId }, { participant2Id: userId }],
        },
      },
    });
    return { count };
  }
}
