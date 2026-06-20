import { Controller, Post, Body, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { SocialBrandingService } from './social-branding.service';
import { SocialBrandingDto } from './dto';
import { Auth }    from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User }    from 'generated/prisma/client';

@Controller('social-branding')
export class SocialBrandingController {
  private readonly logger = new Logger(SocialBrandingController.name);

  constructor(private readonly socialBrandingService: SocialBrandingService) {}

  /**
   * POST /api/social-branding/recommendations
   * Body: { "network": "linkedin"|"instagram"|"tiktok"|"facebook", "refresh"?: true }
   * Returns full personal brand guide personalized to the user's style profile.
   */
  @Post('recommendations')
  @Auth()
  async getRecommendations(
    @GetUser() user: User,
    @Body() dto: SocialBrandingDto,
  ) {
    try {
      return await this.socialBrandingService.getRecommendations(user.id, dto);
    } catch (err) {
      this.logger.error(`Social branding failed for userId=${user.id}: ${(err as Error).message}`);
      throw new HttpException(
        'No se pudieron generar las recomendaciones. Intentá de nuevo en un momento.',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
  }
}
