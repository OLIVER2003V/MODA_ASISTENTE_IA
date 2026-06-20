import {
  Controller, Get, Post, Body, Patch, Param, Delete,
  UseInterceptors, UploadedFile, ParseFilePipe,
  FileTypeValidator, MaxFileSizeValidator, UseGuards,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UserAttributeService } from './user-attribute.service';
import { CreateUserAttributeDto } from './dto/create-user-attribute.dto';
import { UpdateUserAttributeDto } from './dto/update-user-attribute.dto';
import { JwtAuthGuard } from '../auth/guards';
import { GetUser } from '../auth/decorators/get-user.decorator';

@Controller('user-attribute')
export class UserAttributeController {
  constructor(private readonly userAttributeService: UserAttributeService) {}

  @Post()
  create(@Body() createUserAttributeDto: CreateUserAttributeDto) {
    return this.userAttributeService.create(createUserAttributeDto);
  }

  @Get()
  findAll() {
    return this.userAttributeService.findAll();
  }

  // Ruta específica "by-user" antes de la genérica :id
  @Get('by-user/:userId')
  getByUserId(@Param('userId') userId: string) {
    return this.userAttributeService.findByUserId(userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.userAttributeService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateUserAttributeDto: UpdateUserAttributeDto) {
    return this.userAttributeService.update(id, updateUserAttributeDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.userAttributeService.remove(id);
  }

  @Post('body-photo')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  uploadBodyPhoto(
    @GetUser() user: any,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp)$/i }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.userAttributeService.uploadBodyPhoto(user.id, file);
  }

  @Get('body-photo/url')
  @UseGuards(JwtAuthGuard)
  getBodyPhotoUrl(@GetUser() user: any) {
    return this.userAttributeService.getBodyPhotoUrl(user.id);
  }
}
