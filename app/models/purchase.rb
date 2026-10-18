# One coin pack bought through Stripe Checkout. Coins are credited only by the webhook
# (Purchase#fulfill!), never by the redirect back from Stripe, which anyone could fake.
class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :coin_pack

  enum :status, { pending: 0, paid: 1, refunded: 2, expired: 3 }

  def self.start!(user, coin_pack)
    create!(user:, coin_pack:, coins: coin_pack.total_coins, amount_cents: coin_pack.price_cents, currency: coin_pack.currency)
  end

  # Idempotent: a redelivered or duplicate "paid" event credits the coins only once.
  def fulfill!(payment_intent_id: nil)
    with_lock do
      if pending?
        update!(status: :paid, paid_at: Time.current, stripe_payment_intent_id: payment_intent_id || stripe_payment_intent_id)
        Wallet.new(user).credit!(coins, kind: :purchase, reference: self)
        true
      else
        false
      end
    end
  end

  # Takes back the coins that are still unspent; spent coins can't be clawed back.
  def refund!
    with_lock do
      if paid?
        update!(status: :refunded, refunded_at: Time.current)
        recoverable = [ coins, user.reload.coin_balance ].min
        Wallet.new(user).debit!(recoverable, kind: :refund, reference: self) if recoverable.positive?
        true
      else
        false
      end
    end
  end
end
