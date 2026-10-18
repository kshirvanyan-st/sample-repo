# A driver adding money to their balance through a payment provider. Money is credited only by the
# provider's signed callback (TopUp#fulfill!), never by the redirect back, which anyone could fake.
class TopUp < ApplicationRecord
  AMOUNTS = 1_000..50_000

  belongs_to :driver_profile

  enum :status, { pending: 0, paid: 1, failed: 2, expired: 3 }, validate: true

  validates :amount, numericality: { only_integer: true, in: AMOUNTS }
  validates :provider, presence: true

  # Idempotent: a redelivered or duplicate "paid" callback credits the money only once.
  def fulfill!(payment_id:, amount:)
    raise Payments::Error, "amount mismatch" unless amount.to_i == self.amount

    with_lock do
      next false unless pending?

      update!(status: :paid, paid_at: Time.current, provider_payment_id: payment_id)
      DriverWallet.new(driver_profile).credit!(self.amount, kind: :top_up, reference: self)
      true
    end
  end

  def fail!
    with_lock { update!(status: :failed) if pending? }
  end
end
