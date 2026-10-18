# Daily early-warning email: revenue falling off, refunds climbing, or the coin economy
# draining (gifts outpacing purchases). Thresholds are deliberately simple; tune with data.
class RevenueAlertsJob < ApplicationJob
  queue_as :default

  REVENUE_DROP = 0.3       # yesterday 30% below the previous week's daily average
  REFUND_RATE = 0.005      # refunds above 0.5% of revenue over 30 days (card networks flag ~0.75%)
  MIN_WEEKLY_REVENUE_CENTS = 5_000 # don't alert on noise before there's real revenue

  def perform
    DailyMetricsJob.perform_now
    messages = [ revenue_drop, refund_rate ].compact
    AdminMailer.alerts(messages).deliver_later if messages.any? && AdminMailer.recipients.any?
    messages
  end

  private
    def revenue_drop
      yesterday = DailyMetric.find_by(date: Date.yesterday)&.revenue_cents.to_i
      week = DailyMetric.between((Date.yesterday - 7)..(Date.yesterday - 1)).sum(:revenue_cents)
      return if week < MIN_WEEKLY_REVENUE_CENTS

      average = week / 7.0
      return unless yesterday < average * (1 - REVENUE_DROP)

      "Revenue yesterday was #{dollars(yesterday)}, #{((1 - yesterday / average) * 100).round}% below the 7-day average of #{dollars(average)}."
    end

    def refund_rate
      rows = DailyMetric.between(29.days.ago.to_date..Date.current)
      revenue = rows.sum(:revenue_cents)
      refunds = rows.sum(:refunds_cents)
      return if revenue < MIN_WEEKLY_REVENUE_CENTS || refunds <= revenue * REFUND_RATE

      "Refunds are #{(refunds * 100.0 / revenue).round(2)}% of revenue over 30 days (#{dollars(refunds)} of #{dollars(revenue)})."
    end

    def dollars(cents)
      ActiveSupport::NumberHelper.number_to_currency(cents / 100.0)
    end
end
