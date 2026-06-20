import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import * as multer from 'multer';
import { PostService } from './post.service';
import { PostController } from './post.controller';
import { PrismaModule } from 'src/common/prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    MulterModule.register({ storage: multer.memoryStorage() }),
  ],
  controllers: [PostController],
  providers: [PostService],
})
export class PostModule {}
