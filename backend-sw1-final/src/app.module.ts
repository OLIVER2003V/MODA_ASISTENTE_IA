import { Module } from '@nestjs/common';
import { UsersModule } from './features/users/users.module';
import { AuthModule } from './features/auth/auth.module';
import { UserAttributeModule } from './features/user-attribute/user-attribute.module';
import { ClosetModule } from './features/closet/closet.module';
import { GarmentModule } from './features/garment/garment.module';
import { OutfitModule } from './features/outfit/outfit.module';
import { StorageModule } from './common/storage/storage.module';
import { NotificationsModule } from './common/notifications/notifications.module';
import { InAppNotificationModule } from './common/in-app-notification/in-app-notification.module';
import { AiModule } from './features/ai/ai.module';
import { PostModule } from './features/post/post.module';
import { ChatModule } from './features/chat/chat.module';
import { HairstyleModule }       from './features/hairstyle/hairstyle.module';
import { SocialBrandingModule }  from './features/social-branding/social-branding.module';
import { SubscriptionModule }    from './features/subscription/subscription.module';
import { DmModule }              from './features/dm/dm.module';
import { NotificationModule }    from './features/notification/notification.module';

@Module({
  imports: [
    StorageModule,
    NotificationsModule,
    InAppNotificationModule,
    UsersModule,
    AuthModule,
    UserAttributeModule,
    ClosetModule,
    GarmentModule,
    OutfitModule,
    AiModule,
    PostModule,
    ChatModule,
    HairstyleModule,
    SocialBrandingModule,
    SubscriptionModule,
    DmModule,
    NotificationModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
