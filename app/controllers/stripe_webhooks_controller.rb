# Stripe → Rails. Signature-checked, and each event is handled at most once (StripeEvent).
# Subscribe the endpoint to: checkout.session.completed, checkout.session.async_payment_succeeded,
# checkout.session.expired, charge.refunded.
class StripeWebhooksController < ActionController::API
  def create
    event = Stripe::Webhook.construct_event(request.raw_post, request.headers["Stripe-Signature"].to_s,
      Rails.configuration.x.stripe.webhook_secret.to_s)
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  else
    StripeEvent.transaction do
      handle(event) if StripeEvent.record_once(event)
    end
    head :ok
  end

  private
    def handle(event)
      object = event.data.object

      case event.type
      when "checkout.session.completed", "checkout.session.async_payment_succeeded"
        fulfill(object) if object.payment_status == "paid"
      when "checkout.session.expired"
        purchase_for(object)&.then { |purchase| purchase.expired! if purchase.pending? }
      when "charge.refunded"
        Purchase.find_by(stripe_payment_intent_id: object.payment_intent)&.refund!
      end
    end

    def fulfill(session)
      purchase = purchase_for(session)
      return Rails.logger.warn("Stripe session #{session.id} has no matching purchase") unless purchase
      return Rails.logger.error("Stripe session #{session.id} amount doesn't match purchase #{purchase.id}") unless paid_in_full?(session, purchase)

      purchase.fulfill!(payment_intent_id: session.payment_intent)
    end

    def purchase_for(session)
      Purchase.find_by(stripe_checkout_session_id: session.id) || Purchase.find_by(id: session.client_reference_id)
    end

    def paid_in_full?(session, purchase)
      session.amount_total == purchase.amount_cents && session.currency == purchase.currency
    end
end
