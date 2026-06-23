import {
  Controller,
  Post,
  Get,
  Body,
  Req,
  Headers,
  HttpCode,
  Logger,
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { SubscriptionService } from './subscription.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { Auth } from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User } from 'generated/prisma/client';

@Controller('subscription')
export class SubscriptionController {
  private readonly logger = new Logger(SubscriptionController.name);

  constructor(private readonly subscriptionService: SubscriptionService) {}

  @Post('checkout')
  @Auth()
  async createCheckout(
    @GetUser() user: User,
    @Body() dto: CreateSubscriptionDto,
  ) {
    try {
      return await this.subscriptionService.createCheckout(user.id, dto.planId);
    } catch (err) {
      this.logger.error(
        `Checkout failed for userId=${user.id}: ${(err as Error).message}`,
      );
      throw err;
    }
  }

  @Post('webhook')
  @HttpCode(200)
  handleWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') sig: string,
  ) {
    const rawBody = req.rawBody;
    if (!rawBody) {
      this.logger.error(
        'rawBody is empty — ensure rawBody:true in NestFactory.create',
      );
    }
    return this.subscriptionService.handleWebhook(
      rawBody ?? Buffer.alloc(0),
      sig,
    );
  }

  @Get('status')
  @Auth()
  getStatus(@GetUser() user: User) {
    return this.subscriptionService.getStatus(user.id);
  }
}
