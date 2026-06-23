import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
  ParseFilePipe,
  FileTypeValidator,
  MaxFileSizeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';
import { SetAvatarDto } from './dto/set-avatar.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { Auth } from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User } from 'generated/prisma/client';

@ApiTags('Users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // ── FCM token ──────────────────────────────────────────────────────────────

  @Patch('register-fcm/:userId')
  @Auth()
  @ApiOperation({ summary: 'Registrar token FCM del dispositivo' })
  registerFcmToken(@Body() dto: RegisterFcmTokenDto, @GetUser() user: User) {
    return this.usersService.registerFcmToken(user.id, dto);
  }

  // ── Editar perfil ─────────────────────────────────────────────────────────

  @Patch('profile')
  @Auth()
  @ApiOperation({ summary: 'Actualizar nombre del perfil' })
  updateProfile(@GetUser() user: User, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(user.id, dto);
  }

  // ── Profile photo ──────────────────────────────────────────────────────────

  @Post('photo')
  @Auth()
  @ApiOperation({ summary: 'Subir o reemplazar foto de perfil' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'Foto de perfil (jpg/png/webp, max 5 MB)',
        },
      },
    },
  })
  @UseInterceptors(FileInterceptor('file'))
  uploadProfilePhoto(
    @GetUser() user: User,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp)$/i }),
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.usersService.uploadProfilePhoto(user.id, file);
  }

  @Delete('photo')
  @Auth()
  @ApiOperation({ summary: 'Eliminar foto de perfil' })
  removeProfilePhoto(@GetUser() user: User) {
    return this.usersService.removeProfilePhoto(user.id);
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────

  @Patch('avatar')
  @Auth()
  @ApiOperation({ summary: 'Elegir estilo de avatar' })
  setAvatar(@GetUser() user: User, @Body() dto: SetAvatarDto) {
    return this.usersService.setAvatar(user.id, dto);
  }

  // ── Sugerencias y búsqueda ─────────────────────────────────────────────────

  @Get('suggestions')
  @Auth()
  getSuggestions(@GetUser() user: User) {
    return this.usersService.getSuggestions(user.id);
  }

  @Get('search')
  @Auth()
  searchUsers(@Query('q') q: string, @GetUser() user: User) {
    return this.usersService.searchUsers(q ?? '', user.id);
  }

  // ── Perfil público ─────────────────────────────────────────────────────────

  @Get(':id/public-profile')
  getPublicProfile(
    @Param('id') id: string,
    @Query('viewerId') viewerId?: string,
  ) {
    return this.usersService.getPublicProfile(id, viewerId);
  }

  // ── Follow ─────────────────────────────────────────────────────────────────

  @Post(':id/follow')
  @Auth()
  follow(@Param('id') targetId: string, @GetUser() user: User) {
    return this.usersService.follow(user.id, targetId);
  }

  @Delete(':id/follow')
  @Auth()
  unfollow(@Param('id') targetId: string, @GetUser() user: User) {
    return this.usersService.unfollow(user.id, targetId);
  }

  @Get(':id/followers')
  getFollowers(@Param('id') id: string) {
    return this.usersService.getFollowers(id);
  }

  @Get(':id/following')
  getFollowing(@Param('id') id: string) {
    return this.usersService.getFollowing(id);
  }
}
