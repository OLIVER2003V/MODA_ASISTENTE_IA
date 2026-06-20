import { Injectable } from '@nestjs/common';
// Stripe v22 uses `export =` — must use import-require syntax for CJS interop
import StripeLib = require('stripe');
import { envs } from 'src/config/envs';

@Injectable()
export class StripeService {
  private readonly stripe: InstanceType<typeof StripeLib>;

  constructor() {
    this.stripe = new StripeLib(envs.stripe.secretKey);
  }

  get client(): InstanceType<typeof StripeLib> {
    return this.stripe;
  }
}
