import {
  Controller, Get, Post, Body, Param, Delete, Query,
  ParseIntPipe, DefaultValuePipe,
  UseInterceptors, UploadedFile, BadRequestException,
} from '@nestjs/common';
import { IsEnum, IsOptional } from 'class-validator';
import { ReactionType } from 'generated/prisma/client';

class ReactDto {
  @IsOptional() @IsEnum(ReactionType) reactionType?: ReactionType;
}
import { FileInterceptor } from '@nestjs/platform-express';
import { PostService }      from './post.service';
import { CreatePostDto, CreateCommentDto } from './dto/create-post.dto';
import { Auth }    from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User }    from 'generated/prisma/client';

@Controller('post')
export class PostController {
  constructor(private readonly postService: PostService) {}

  // ─── Upload imagen (paso previo al POST /post) ──────────────────────────────

  @Post('upload-image')
  @Auth()
  @UseInterceptors(FileInterceptor('file', {
    limits: { fileSize: 10 * 1024 * 1024 },
  }))
  uploadImage(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Se requiere una imagen');
    return this.postService.uploadPostImage(file);
  }

  // ─── Posts ──────────────────────────────────────────────────────────────────

  @Post()
  @Auth()
  create(@Body() dto: CreatePostDto, @GetUser() user: User) {
    return this.postService.create(dto, user.id);
  }

  @Get()
  findAll(
    @Query('page',  new DefaultValuePipe(1),  ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.postService.findAll(page, Math.min(limit, 50));
  }

  @Get('feed/following')
  @Auth()
  followingFeed(
    @GetUser() user: User,
    @Query('page',  new DefaultValuePipe(1),  ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.postService.findFollowingFeed(user.id, page, Math.min(limit, 50));
  }

  @Get('my/reactions')
  @Auth()
  getMyReactions(@GetUser() user: User) {
    return this.postService.getUserReactions(user.id);
  }

  @Get('tag/:tag')
  findByTag(
    @Param('tag') tag: string,
    @Query('page',  new DefaultValuePipe(1),  ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.postService.findByTag(tag, page, Math.min(limit, 50));
  }

  @Get('user/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.postService.findByUser(userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.postService.findOne(id);
  }

  @Delete(':id')
  @Auth()
  remove(@Param('id') id: string, @GetUser() user: User) {
    return this.postService.remove(id, user.id);
  }

  // ─── Reacciones ─────────────────────────────────────────────────────────────

  @Post(':id/react')
  @Auth()
  react(@Param('id') id: string, @GetUser() user: User, @Body() dto: ReactDto) {
    return this.postService.react(id, user.id, dto.reactionType);
  }

  @Get(':id/reactions/summary')
  getReactionSummary(@Param('id') id: string) {
    return this.postService.getReactionSummary(id);
  }

  @Delete(':id/react')
  @Auth()
  unreact(@Param('id') id: string, @GetUser() user: User) {
    return this.postService.unreact(id, user.id);
  }

  @Get(':id/reactions')
  getReactions(@Param('id') id: string) {
    return this.postService.getReactions(id);
  }

  // ─── Comentarios ────────────────────────────────────────────────────────────

  @Post(':id/comment')
  @Auth()
  createComment(
    @Param('id') postId: string,
    @GetUser() user: User,
    @Body() dto: CreateCommentDto,
  ) {
    return this.postService.createComment(postId, user.id, dto);
  }

  @Get(':id/comments')
  getComments(@Param('id') postId: string) {
    return this.postService.getComments(postId);
  }

  @Delete('comment/:commentId')
  @Auth()
  deleteComment(@Param('commentId') commentId: string, @GetUser() user: User) {
    return this.postService.deleteComment(commentId, user.id);
  }
}
