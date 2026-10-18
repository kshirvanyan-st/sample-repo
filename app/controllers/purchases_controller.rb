class PurchasesController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: :create, by: -> { Current.user.id }, with: -> { redirect_to coins_path, alert: "Too many attempts, try again in a minute." }

  def create
    coin_pack = CoinPack.available.find(params[:coin_pack_id])
    purchase = Purchase.start!(Current.user, coin_pack)

    if Stripe.api_key.present?
      session = Stripe::Checkout::Session.create(checkout_params(purchase, coin_pack))
      purchase.update!(stripe_checkout_session_id: session.id)
      redirect_to session.url, allow_other_host: true, status: :see_other
    elsif Rails.env.development?
      # No Stripe keys locally: pretend the payment succeeded so the coin flow can be tried.
      purchase.fulfill!
      redirect_to coins_path(purchase: purchase.id), notice: "Development mode: #{purchase.coins} coins added without payment."
    else
      redirect_to coins_path, alert: "Coin purchases aren't available right now."
    end
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe Checkout failed: #{e.message}")
    redirect_to coins_path, alert: "We couldn't start the payment. Please try again."
  end

  private
    def checkout_params(purchase, coin_pack)
      {
        mode: "payment",
        client_reference_id: purchase.id.to_s,
        metadata: { purchase_id: purchase.id },
        customer_email: Current.user.email_address,
        line_items: [ {
          quantity: 1,
          price_data: {
            currency: coin_pack.currency,
            unit_amount: coin_pack.price_cents,
            product_data: { name: "#{coin_pack.total_coins} Spark coins", description: coin_pack.name }
          }
        } ],
        success_url: coins_url(purchase: purchase.id),
        cancel_url: coins_url
      }
    end
end
