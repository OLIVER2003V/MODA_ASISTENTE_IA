import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
} from '@nestjs/common';
import { ClosetService } from './closet.service';
import { CreateClosetDto } from './dto/create-closet.dto';
import { UpdateClosetDto } from './dto/update-closet.dto';
import { Auth } from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User } from 'generated/prisma/client';

@Controller('closet')
export class ClosetController {
  constructor(private readonly closetService: ClosetService) {}

  @Post()
  @Auth()
  create(@Body() dto: CreateClosetDto, @GetUser() user: User) {
    return this.closetService.create(dto, user.id);
  }

  @Get('user/:userId')
  findByUserId(@Param('userId') userId: string) {
    return this.closetService.findByUserId(userId);
  }

  @Get()
  @Auth()
  findAll() {
    return this.closetService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.closetService.findOne(id);
  }

  @Patch(':id')
  @Auth()
  update(
    @Param('id') id: string,
    @Body() dto: UpdateClosetDto,
    @GetUser() user: User,
  ) {
    return this.closetService.update(id, dto, user.id);
  }

  @Delete(':id')
  @Auth()
  remove(@Param('id') id: string, @GetUser() user: User) {
    return this.closetService.remove(id, user.id);
  }
}
