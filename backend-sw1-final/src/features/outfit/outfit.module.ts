import { Module } from '@nestjs/common';
import { OutfitService } from './outfit.service';
import { OutfitController } from './outfit.controller';
import { PrismaModule } from 'src/common/prisma/prisma.module';
import { AiModule } from 'src/features/ai/ai.module';
import { StorageModule } from 'src/common/storage/storage.module';

@Module({
  imports: [PrismaModule, AiModule, StorageModule],
  controllers: [OutfitController],
  providers: [OutfitService],
})
export class OutfitModule {}
