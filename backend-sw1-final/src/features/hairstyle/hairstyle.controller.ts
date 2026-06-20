import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  UseInterceptors,
  UploadedFiles,
  UploadedFile,
  ParseFilePipe,
  FileTypeValidator,
  MaxFileSizeValidator,
  UseGuards,
} from '@nestjs/common';
import { FilesInterceptor, FileInterceptor } from '@nestjs/platform-express';
import { HairstyleService } from './hairstyle.service';
import { UploadHairstylesDto } from './dto';
import { JwtAuthGuard } from '../auth/guards';
import { GetUser } from '../auth/decorators';
import { PremiumGuard } from 'src/common/guards/premium.guard';

@Controller('hairstyle')
export class HairstyleController {
  constructor(private readonly hairstyleService: HairstyleService) {}

  @Post('upload')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FilesInterceptor('files', 20))
  async upload(
    @Body() dto: UploadHairstylesDto,
    @UploadedFiles(
      new ParseFilePipe({
        validators: [
          new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp|avif)$/i }),
        ],
      }),
    )
    files: Express.Multer.File[],
  ) {
    return this.hairstyleService.uploadHairstyles(files, dto.gender);
  }

  @Get()
  async findAll() {
    return this.hairstyleService.findAll();
  }

  @Post('recommend')
  @UseGuards(JwtAuthGuard, PremiumGuard)
  @UseInterceptors(FileInterceptor('file'))
  async recommend(
    @GetUser() user: any,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp)$/i }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.hairstyleService.recommendFromFace(file, user.id);
  }

  @Post('try-on')
  @UseGuards(JwtAuthGuard, PremiumGuard)
  @UseInterceptors(FileInterceptor('file'))
  async tryOn(
    @GetUser() user: any,
    @Body('hairstyleId') hairstyleId: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp)$/i }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.hairstyleService.tryOnHairstyle(file, hairstyleId, user.id);
  }

  @Post('favorite/:hairstyleId')
  @UseGuards(JwtAuthGuard)
  async addFavorite(
    @GetUser() user: any,
    @Param('hairstyleId') hairstyleId: string,
  ) {
    return this.hairstyleService.addFavorite(user.id, hairstyleId);
  }

  @Delete('favorite/:hairstyleId')
  @UseGuards(JwtAuthGuard)
  async removeFavorite(
    @GetUser() user: any,
    @Param('hairstyleId') hairstyleId: string,
  ) {
    return this.hairstyleService.removeFavorite(user.id, hairstyleId);
  }

  @Get('favorites')
  @UseGuards(JwtAuthGuard)
  async getFavorites(@GetUser() user: any) {
    return this.hairstyleService.getFavorites(user.id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async remove(@Param('id') id: string) {
    return this.hairstyleService.remove(id);
  }
}
