import { IsBoolean, IsEnum, IsOptional } from 'class-validator';

export enum SocialNetwork {
  LINKEDIN  = 'linkedin',
  INSTAGRAM = 'instagram',
  TIKTOK    = 'tiktok',
  FACEBOOK  = 'facebook',
}

export class SocialBrandingDto {
  @IsEnum(SocialNetwork, {
    message: 'network debe ser: linkedin, instagram, tiktok o facebook',
  })
  network: SocialNetwork;

  @IsOptional()
  @IsBoolean()
  refresh?: boolean;
}
