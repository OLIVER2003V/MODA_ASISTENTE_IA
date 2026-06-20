import { Module } from '@nestjs/common';
import { SocialBrandingController } from './social-branding.controller';
import { SocialBrandingService }    from './social-branding.service';
import { PrismaModule } from 'src/common/prisma/prisma.module';
import { AiModule }     from 'src/features/ai/ai.module';

@Module({
  imports: [PrismaModule, AiModule],
  controllers: [SocialBrandingController],
  providers:   [SocialBrandingService],
})
export class SocialBrandingModule {}
