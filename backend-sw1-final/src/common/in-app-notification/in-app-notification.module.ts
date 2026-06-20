import { Global, Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { InAppNotificationService } from './in-app-notification.service';

@Global()
@Module({
  imports:   [PrismaModule],
  providers: [InAppNotificationService],
  exports:   [InAppNotificationService],
})
export class InAppNotificationModule {}
