import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  FileTypeValidator,
  UseGuards,
  MaxFileSizeValidator,
  ForbiddenException,
  Delete,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ChatService } from './chat.service';
import { SendMessageDto } from './dto';
import { JwtAuthGuard } from '../auth/guards';
import { GetUser } from '../auth/decorators/get-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('conversations')
  async startConversation(
    @GetUser() user: any,
    @Body() body?: { lat?: number; lon?: number },
  ) {
    return this.chatService.startConversation(user.id, body?.lat, body?.lon);
  }

  @Get('conversations/:userId')
  async getConversationsByUser(
    @GetUser() user: any,
    @Param('userId') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    if (user.id !== userId) throw new ForbiddenException('No tienes permiso para ver estas conversaciones');
    return this.chatService.getConversationsByUser(userId, page, limit);
  }

  @Post('conversations/:id/messages')
  async sendMessage(
    @GetUser() user: any,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(user.id, id, dto.content);
  }

  @Post('conversations/:id/face-image')
  @UseInterceptors(FileInterceptor('file'))
  async sendFaceImage(
    @GetUser() user: any,
    @Param('id') id: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }), // 5MB máximo de RAM
          new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp)$/i }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.chatService.handleFaceImage(user.id, id, file);
  }

  @Post('conversations/:id/audio')
  @UseInterceptors(FileInterceptor('file'))
  async sendAudio(
    @GetUser() user: any,
    @Param('id') id: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 25 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: /(m4a|mp4|mp3|wav|webm|ogg|aac|mpeg)$/i }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.chatService.sendAudioMessage(user.id, id, file);
  }

  @Delete('conversations/:id')
  async deleteConversation(
    @GetUser() user: any,
    @Param('id') id: string,
  ) {
    return this.chatService.deleteConversation(user.id, id);
  }
}
