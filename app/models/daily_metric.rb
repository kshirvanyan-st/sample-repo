# One row of business numbers per day (UTC), recomputed by DailyMetricsJob.
class DailyMetric < ApplicationRecord
  scope :between, ->(range) { where(date: range).order(:date) }

  # Recomputes and stores the numbers for one day from the source tables.
  def self.compute!(date)
    day = date.all_day
    paid = Purchase.where(paid_at: day).where(status: %i[ paid refunded ])
    coin_entries = LedgerEntry.coins.where(created_at: day)

    attributes = {
      signups: User.where(created_at: day).count,
      active_users: Ahoy::Visit.where(started_at: day).where.not(user_id: nil).distinct.count(:user_id),
      payers: paid.distinct.count(:user_id),
      purchases: paid.count,
      revenue_cents: paid.sum(:amount_cents),
      refunds_cents: Purchase.refunded.where(refunded_at: day).sum(:amount_cents),
      coins_purchased: coin_entries.purchase.sum(:amount),
      coins_spent: -coin_entries.gift_sent.sum(:amount),
      gift_coins: GiftTransaction.where(created_at: day).sum(:coins),
      matches: Match.where(created_at: day).count,
      messages: Message.where(created_at: day).count,
      streams: Stream.where(started_at: day).count,
      viewer_seconds: Stream.where(started_at: day).sum(:viewer_seconds)
    }

    upsert(attributes.merge(date: date, created_at: Time.current, updated_at: Time.current), unique_by: :date)
  end

  def arpu_cents
    active_users.zero? ? 0 : revenue_cents / active_users.to_f
  end

  def payer_conversion
    active_users.zero? ? 0 : payers / active_users.to_f
  end
end
