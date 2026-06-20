import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { SubscriptionStatus } from 'generated/prisma/client';

@Injectable()
export class PremiumGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const user = context.switchToHttp().getRequest().user;
    if (!user?.id) return false;

    const sub = await this.prisma.subscription.findUnique({
      where: { userId: user.id },
      select: { status: true },
    });

    if (sub?.status !== SubscriptionStatus.PREMIUM) {
      throw new ForbiddenException('premium_required');
    }

    return true;
  }
}
