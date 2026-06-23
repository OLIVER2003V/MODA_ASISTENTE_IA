import { Controller, Get, Post, Param, Body } from '@nestjs/common';
import { DmService } from './dm.service';
import { Auth } from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User } from 'generated/prisma/client';
import { IsString, IsNotEmpty, MaxLength } from 'class-validator';

class SendMessageDto {
  @IsString() @IsNotEmpty() @MaxLength(2000) content: string;
}

@Controller('dm')
@Auth()
export class DmController {
  constructor(private readonly dmService: DmService) {}

  @Get()
  getConversations(@GetUser() user: User) {
    return this.dmService.getConversations(user.id);
  }

  @Get('unread-count')
  getUnreadCount(@GetUser() user: User) {
    return this.dmService.getUnreadCount(user.id);
  }

  @Post('with/:userId')
  getOrCreate(@Param('userId') targetId: string, @GetUser() user: User) {
    return this.dmService.getOrCreate(user.id, targetId);
  }

  @Get(':conversationId/messages')
  getMessages(
    @Param('conversationId') conversationId: string,
    @GetUser() user: User,
  ) {
    return this.dmService.getMessages(conversationId, user.id);
  }

  @Post(':conversationId/messages')
  sendMessage(
    @Param('conversationId') conversationId: string,
    @GetUser() user: User,
    @Body() dto: SendMessageDto,
  ) {
    return this.dmService.sendMessage(conversationId, user.id, dto.content);
  }
}
