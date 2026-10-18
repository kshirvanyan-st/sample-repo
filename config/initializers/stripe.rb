# Stripe Checkout sells coin packs; the webhook (StripeWebhooksController) credits them.
#   STRIPE_SECRET_KEY      sk_live_... / sk_test_...
#   STRIPE_WEBHOOK_SECRET  whsec_... for https://<APP_HOST>/stripe/webhooks
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
Stripe.max_network_retries = 2

Rails.application.config.x.stripe.webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"]
