import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { StripeService } from './stripe.service';
import { SubscriptionPlan } from './dto/create-subscription.dto';
import { envs } from 'src/config/envs';
import { SubscriptionStatus, PaymentStatus } from 'generated/prisma/client';

// Stripe dahlia API (v22) interfaces — payment_intent is no longer on Invoice
interface DahliaInvoice {
  subscription?: string | { id: string } | null;
  amount_paid:   number;
  currency:      string;
}

interface DahliaInvoicePayment {
  id:      string;
  payment: { payment_intent: string; type: string } | null;
}

interface StripeSub {
  id:                  string;
  status:              string;
  current_period_end:  number | null | undefined;
}

interface StripeEvent {
  type: string;
  data: { object: unknown };
}

function safePeriodEnd(ts: number | null | undefined): Date | null {
  if (!ts || !Number.isFinite(ts)) return null;
  return new Date(ts * 1000);
}

@Injectable()
export class SubscriptionService {
  private readonly logger = new Logger(SubscriptionService.name);

  constructor(
    private readonly prisma:  PrismaService,
    private readonly stripe:  StripeService,
  ) {}

  // ─── Checkout ────────────────────────────────────────────────────────────────

  async createCheckout(userId: string, planId: SubscriptionPlan) {
    const user = await this.prisma.user.findUnique({
      where:   { id: userId },
      include: { subscription: true },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    // If already PREMIUM, nothing to do
    if (user.subscription?.status === SubscriptionStatus.PREMIUM) {
      throw new BadRequestException('El usuario ya tiene una suscripción activa');
    }

    let customerId = user.stripeCustomerId;

    if (!customerId) {
      const customer = await this.stripe.client.customers.create({
        email:    user.email,
        name:     user.name ?? undefined,
        metadata: { userId },
      });
      customerId = customer.id;
      await this.prisma.user.update({
        where: { id: userId },
        data:  { stripeCustomerId: customerId },
      });
    }

    // If there's an existing incomplete Stripe subscription, reuse it instead of creating another
    if (user.subscription?.stripeSubscriptionId) {
      try {
        const existing = await this.stripe.client.subscriptions.retrieve(
          user.subscription.stripeSubscriptionId,
        ) as unknown as StripeSub & { latest_invoice: string | null };

        if (existing.status === 'active' || existing.status === 'trialing') {
          // Already active — sync DB and return early
          const currentPeriodEnd = safePeriodEnd(existing.current_period_end);
          await this.prisma.subscription.update({
            where: { userId },
            data:  { status: SubscriptionStatus.PREMIUM, currentPeriodEnd },
          });
          throw new BadRequestException('El usuario ya tiene una suscripción activa');
        }

        if (existing.status === 'incomplete' && existing.latest_invoice) {
          // Reuse the existing incomplete subscription
          const clientSecret = await this.getClientSecretFromInvoice(existing.latest_invoice);
          return { clientSecret, subscriptionId: existing.id };
        }
      } catch (e) {
        if ((e as { status?: number }).status !== 404 && !(e instanceof BadRequestException)) {
          this.logger.warn(`Could not retrieve existing sub: ${(e as Error).message}`);
        } else {
          throw e;
        }
      }
    }

    const priceId =
      planId === SubscriptionPlan.MONTHLY
        ? envs.stripe.monthlyPriceId
        : envs.stripe.annualPriceId;

    const stripeSub = await this.stripe.client.subscriptions.create({
      customer:         customerId,
      items:            [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
    });

    await this.prisma.subscription.upsert({
      where:  { userId },
      create: { userId, stripeSubscriptionId: stripeSub.id, status: SubscriptionStatus.FREE },
      update: { stripeSubscriptionId: stripeSub.id },
    });

    const rawSub    = stripeSub as unknown as { latest_invoice: string | null };
    const invoiceId = rawSub.latest_invoice;
    if (!invoiceId) throw new Error('Stripe no generó una invoice para esta suscripción');

    const clientSecret = await this.getClientSecretFromInvoice(invoiceId);

    return { clientSecret, subscriptionId: stripeSub.id };
  }

  // ─── Webhook ─────────────────────────────────────────────────────────────────

  async handleWebhook(rawBody: Buffer, signature: string) {
    const secret = envs.stripe.webhookSecret;
    if (!secret) {
      this.logger.warn('STRIPE_WEBHOOK_SECRET not set — skipping signature check');
    }

    let event: StripeEvent;
    try {
      event = this.stripe.client.webhooks.constructEvent(
        rawBody,
        signature,
        secret ?? '',
      ) as unknown as StripeEvent;
    } catch (err) {
      this.logger.error(`Webhook signature failed: ${(err as Error).message}`);
      throw new BadRequestException('Webhook inválido');
    }

    this.logger.log(`Stripe event: ${event.type}`);

    switch (event.type) {
      case 'invoice.payment_succeeded':
        await this.onPaymentSucceeded(event.data.object as DahliaInvoice);
        break;
      case 'invoice.payment_failed':
        await this.onPaymentFailed(event.data.object as DahliaInvoice);
        break;
      case 'customer.subscription.deleted':
        await this.onSubscriptionDeleted(event.data.object as StripeSub);
        break;
      case 'customer.subscription.updated':
        await this.onSubscriptionUpdated(event.data.object as StripeSub);
        break;
    }

    return { received: true };
  }

  // ─── Status ──────────────────────────────────────────────────────────────────

  async getStatus(userId: string) {
    const sub = await this.prisma.subscription.findUnique({ where: { userId } });

    // If DB says FREE but there's a Stripe subscription, check Stripe directly.
    // This covers the case where the webhook didn't arrive (local dev without CLI).
    if (sub?.stripeSubscriptionId && sub.status !== SubscriptionStatus.PREMIUM) {
      try {
        const stripeSub = await this.stripe.client.subscriptions.retrieve(
          sub.stripeSubscriptionId,
        ) as unknown as StripeSub;

        if (stripeSub.status === 'active' || stripeSub.status === 'trialing') {
          const currentPeriodEnd = safePeriodEnd(stripeSub.current_period_end);
          await this.prisma.subscription.update({
            where: { userId },
            data:  { status: SubscriptionStatus.PREMIUM, currentPeriodEnd },
          });
          this.logger.log(`Synced PREMIUM from Stripe for userId=${userId} (webhook fallback)`);
          return { status: SubscriptionStatus.PREMIUM, currentPeriodEnd, isPremium: true };
        }
      } catch (e) {
        this.logger.warn(`Could not sync Stripe status for userId=${userId}: ${(e as Error).message}`);
      }
    }

    return {
      status:           sub?.status           ?? SubscriptionStatus.FREE,
      currentPeriodEnd: sub?.currentPeriodEnd ?? null,
      isPremium:        sub?.status === SubscriptionStatus.PREMIUM,
    };
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  // Dahlia API: PaymentIntent lives at InvoicePayment.payment.payment_intent
  private async getClientSecretFromInvoice(invoiceId: string): Promise<string> {
    const list = await (this.stripe.client as any).invoicePayments.list({ invoice: invoiceId });
    const ip   = (list.data as DahliaInvoicePayment[])[0];

    if (!ip) throw new Error('No InvoicePayment found for invoice');

    const piId = ip.payment?.payment_intent;
    if (!piId)  throw new Error('No payment_intent ID in InvoicePayment.payment');

    const pi = await this.stripe.client.paymentIntents.retrieve(piId) as unknown as { client_secret: string };
    if (!pi.client_secret) throw new Error('PaymentIntent has no client_secret');

    return pi.client_secret;
  }

  private stripeSubId(invoice: DahliaInvoice): string | undefined {
    if (!invoice.subscription) return undefined;
    return typeof invoice.subscription === 'string'
      ? invoice.subscription
      : invoice.subscription.id;
  }

  // ─── Webhook handlers ────────────────────────────────────────────────────────

  private async onPaymentSucceeded(invoice: DahliaInvoice) {
    const subId = this.stripeSubId(invoice);
    if (!subId) return;

    const stripeSub        = await this.stripe.client.subscriptions.retrieve(subId) as unknown as StripeSub;
    const currentPeriodEnd = safePeriodEnd(stripeSub.current_period_end);

    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: subId },
      data:  { status: SubscriptionStatus.PREMIUM, currentPeriodEnd },
    });

    // Log the payment (best-effort)
    const sub = await this.prisma.subscription.findFirst({ where: { stripeSubscriptionId: subId } });
    if (sub && invoice.amount_paid > 0) {
      // In dahlia, get PI ID via InvoicePayments list if we have invoice ID
      this.logger.log(`Payment succeeded for subscription ${subId}, amount=${invoice.amount_paid}`);
    }
  }

  private async onPaymentFailed(invoice: DahliaInvoice) {
    const subId = this.stripeSubId(invoice);
    if (!subId) return;

    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: subId },
      data:  { status: SubscriptionStatus.PAST_DUE },
    });
  }

  private async onSubscriptionDeleted(sub: StripeSub) {
    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: sub.id },
      data:  { status: SubscriptionStatus.CANCELLED, currentPeriodEnd: null },
    });
  }

  private async onSubscriptionUpdated(sub: StripeSub) {
    const statusMap: Record<string, SubscriptionStatus> = {
      active:             SubscriptionStatus.PREMIUM,
      trialing:           SubscriptionStatus.PREMIUM,
      past_due:           SubscriptionStatus.PAST_DUE,
      unpaid:             SubscriptionStatus.PAST_DUE,
      canceled:           SubscriptionStatus.CANCELLED,
      incomplete:         SubscriptionStatus.FREE,
      incomplete_expired: SubscriptionStatus.FREE,
      paused:             SubscriptionStatus.FREE,
    };

    const status           = statusMap[sub.status] ?? SubscriptionStatus.FREE;
    const currentPeriodEnd = safePeriodEnd(sub.current_period_end);

    await this.prisma.subscription.updateMany({
      where: { stripeSubscriptionId: sub.id },
      data:  { status, currentPeriodEnd },
    });
  }
}
