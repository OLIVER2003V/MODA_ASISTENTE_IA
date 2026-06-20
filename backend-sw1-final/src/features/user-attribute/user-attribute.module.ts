import { Module } from '@nestjs/common';
import { UserAttributeService } from './user-attribute.service';
import { UserAttributeController } from './user-attribute.controller';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { StorageModule } from 'src/common/storage/storage.module';

@Module({
  imports: [StorageModule],
  controllers: [UserAttributeController],
  providers: [UserAttributeService, PrismaService],
  exports: [UserAttributeService],
})
export class UserAttributeModule {}
