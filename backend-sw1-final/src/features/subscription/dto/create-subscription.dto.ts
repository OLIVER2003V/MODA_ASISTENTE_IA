import { IsEnum } from 'class-validator';

export enum SubscriptionPlan {
  MONTHLY = 'monthly',
  ANNUAL = 'annual',
}

export class CreateSubscriptionDto {
  @IsEnum(SubscriptionPlan, { message: 'planId debe ser monthly o annual' })
  planId: SubscriptionPlan;
}
