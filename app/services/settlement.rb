# What happens to money when a trip ends. Riders pay the driver in cash, so the platform's share
# (commission) is taken from the driver's balance, and cancellation fees are paid to the driver
# who drove to the pickup and collected from the rider on their next trip.
module Settlement
  # Called by TripLifecycle.complete! inside its transaction. The driver collected the whole fare in
  # cash: the commission is on the ride itself, and an earlier cancellation fee included in the fare
  # was already paid to the driver who was cancelled on, so this driver passes it on in full.
  def self.trip_completed!(trip)
    wallet = DriverWallet.new(trip.driver_profile)
    commission = BusinessSetting.current.commission_on(trip.fare - trip.outstanding_fee)
    trip.update!(commission: commission)
    wallet.debit!(commission, kind: :commission, reference: trip) if commission.positive?
    return unless trip.outstanding_fee.positive?

    wallet.debit!(trip.outstanding_fee, kind: :fee_collection, reference: trip)
    trip.rider.decrement!(:outstanding_fee, trip.outstanding_fee)
  end

  # Called by TripLifecycle.cancel! when a rider cancels after the free minutes.
  def self.rider_cancelled_with_fee!(trip)
    return unless trip.cancellation_fee.positive? && trip.driver_profile

    DriverWallet.new(trip.driver_profile).credit!(trip.cancellation_fee, kind: :cancellation_payout, reference: trip)
    trip.rider.increment!(:outstanding_fee, trip.cancellation_fee)
  end

  def self.can_go_online?(driver_profile)
    driver_profile.balance >= BusinessSetting.current.min_balance
  end

  def self.needed_to_go_online(driver_profile)
    [ BusinessSetting.current.min_balance - driver_profile.balance, 0 ].max
  end
end
