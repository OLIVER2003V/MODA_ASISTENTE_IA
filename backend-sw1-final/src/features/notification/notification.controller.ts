import { Controller, Get, Patch, Param } from '@nestjs/common';
import { Auth } from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User } from 'generated/prisma/client';
import { InAppNotificationService } from 'src/common/in-app-notification/in-app-notification.service';

@Controller('notifications')
@Auth()
export class NotificationController {
  constructor(private readonly svc: InAppNotificationService) {}

  @Get()
  getRecent(@GetUser() user: User) {
    return this.svc.getRecent(user.id);
  }

  @Get('unread-count')
  getUnreadCount(@GetUser() user: User) {
    return this.svc.getUnreadCount(user.id).then((count) => ({ count }));
  }

  @Patch('read-all')
  markAllRead(@GetUser() user: User) {
    return this.svc.markAllRead(user.id);
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string, @GetUser() user: User) {
    return this.svc.markRead(id, user.id);
  }
}
