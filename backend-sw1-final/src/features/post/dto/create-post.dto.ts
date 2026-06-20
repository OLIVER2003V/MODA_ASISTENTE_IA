import { IsArray, IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export enum PostTypeDto {
  OUTFIT = 'OUTFIT',
  PHOTO  = 'PHOTO',
  TIP    = 'TIP',
}

export class CreatePostDto {
  @IsEnum(PostTypeDto)
  @IsOptional()
  postType?: PostTypeDto;

  @IsOptional()
  @IsString()
  outfitId?: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  caption?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}

export class CreateCommentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  content: string;
}
