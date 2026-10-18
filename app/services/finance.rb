# Money numbers for the admin finance page, always summed from the ledger and trips (never cached).
module Finance
  def self.summary(range)
    entries = LedgerEntry.where(created_at: range)
    trips = Trip.completed.where(completed_at: range)
    {
      trips: trips.count,
      gmv: trips.sum(:fare),
      commission: -entries.commission.sum(:amount),
      top_ups: entries.top_up.sum(:amount),
      payouts: entries.cancellation_payout.sum(:amount),
      adjustments: entries.adjustment.sum(:amount)
    }
  end

  # What drivers currently owe the platform (negative balances) and hold in credit (positive).
  def self.balances
    { owed_by_drivers: -DriverProfile.where(balance: ...0).sum(:balance), driver_credit: DriverProfile.where(balance: 1..).sum(:balance),
      riders_owe: User.sum(:outstanding_fee) }
  end
end
