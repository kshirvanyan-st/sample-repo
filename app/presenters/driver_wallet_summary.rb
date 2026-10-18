# The driver app's Balance screen (GET /api/v1/driver/wallet): balance, what's needed to go online,
# today's numbers and the latest ledger lines.
class DriverWalletSummary
  def initialize(driver)
    @driver = driver
  end

  def as_json(*)
    settings = BusinessSetting.current
    today = Time.current.all_day
    trips = @driver.trips.completed.where(completed_at: today)
    entries = @driver.ledger_entries.where(created_at: today)
    {
      balance: @driver.balance,
      min_balance: settings.min_balance,
      needed: Settlement.needed_to_go_online(@driver),
      commission_percent: settings.commission_percent,
      top_ups: Payments.enabled?,
      today: { trips: trips.count, cash: trips.sum(:fare), commission: -entries.commission.sum(:amount),
               payouts: entries.cancellation_payout.sum(:amount) },
      entries: @driver.ledger_entries.newest_first.limit(20).map do |entry|
        { id: entry.id, kind: entry.kind, amount: entry.amount, balance_after: entry.balance_after, at: entry.created_at.iso8601 }
      end
    }
  end
end
