import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import * as multer from 'multer';
import { HairstyleController } from './hairstyle.controller';
import { HairstyleService } from './hairstyle.service';
import { PrismaModule } from 'src/common/prisma/prisma.module';
import { PremiumGuard } from 'src/common/guards/premium.guard';
import { AiModule } from 'src/features/ai/ai.module';
import { StorageModule } from 'src/common/storage/storage.module';
import { PythonAiModule } from 'src/common/python/python-ai.module';

@Module({
  imports: [
    MulterModule.register({ storage: multer.memoryStorage() }),
    PrismaModule,
    AiModule,
    StorageModule,
    PythonAiModule,
  ],
  controllers: [HairstyleController],
  providers: [HairstyleService, PremiumGuard],
})
export class HairstyleModule {}
