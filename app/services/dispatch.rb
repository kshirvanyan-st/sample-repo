# Finds a driver for a trip: offer it to the best nearby driver for OFFER_TIMEOUT, then the next
# one, until someone accepts or SEARCH_TIMEOUT passes.
#
# No double booking: candidates are re-checked under a row lock (SKIP LOCKED, so two trips never
# wait on the same driver), accepting locks the trip and the driver, and a partial unique index on
# trips makes a second active trip for one driver impossible even if all of that were bypassed.
module Dispatch
  OFFER_TIMEOUT = 15.seconds
  SEARCH_TIMEOUT = 3.minutes
  RETRY_EVERY = 10.seconds # when nobody is free right now
  RADIUS_M = 5_000
  SHORTLIST = 10

  class Error < StandardError
    # i18n key under dispatch.errors
    def key = message
  end

  # Books a trip from a quote the rider saw, at the quoted price for that class.
  def self.request!(quote:, vehicle_class:)
    raise Error, "quote_expired" if quote.expired?
    raise Error, "unknown_class" unless (fare = quote.prices[vehicle_class.to_s])

    trip = Trip.create!(rider: quote.user, fare_quote: quote, vehicle_class: vehicle_class, fare: fare,
      pickup: quote.pickup, pickup_address: quote.pickup_address, dropoff: quote.dropoff, dropoff_address: quote.dropoff_address)
    offer_next!(trip)
    trip
  rescue ActiveRecord::RecordNotUnique
    raise Error, "already_riding"
  end

  # Approved, online drivers of the right class with a fresh position near the pickup, who are
  # not on a trip, not looking at another offer, and haven't been offered this trip. Nearest first.
  def self.candidates(trip)
    pickup = ActiveRecord::Base.connection.quote("SRID=4326;#{trip.pickup.as_text}")
    DriverProfile.approved.online
      .joins(:user).merge(User.active)
      .joins(:vehicle).where(vehicles: { vehicle_class: Vehicle.vehicle_classes.fetch(trip.vehicle_class) })
      .joins(:location).merge(DriverLocation.fresh)
      .where("ST_DWithin(driver_locations.location, #{pickup}::geography, ?)", RADIUS_M)
      .where.not(id: Trip.busy.select(:driver_profile_id))
      .where.not(id: TripOffer.live.select(:driver_profile_id))
      .where.not(id: trip.offers.select(:driver_profile_id))
      .order(Arel.sql("ST_Distance(driver_locations.location, #{pickup}::geography)"))
      .limit(SHORTLIST)
      .includes(:location)
  end

  def self.offer_next!(trip)
    return unless trip.reload.searching?
    # updated_at: when the search (re)started; a driver handing the trip back restarts it.
    return give_up!(trip) if trip.updated_at < SEARCH_TIMEOUT.ago

    drivers = candidates(trip).to_a
    ranked = drivers.zip(Routing.etas(drivers.map { |driver| driver.location.location }, trip.pickup)).sort_by(&:last)

    offer = Trip.transaction do
      trip.lock!
      next unless trip.searching?

      ranked.lazy.filter_map { |driver, eta| reserve(trip, driver, eta) }.first
    end

    if offer
      Notify.driver(offer.driver_profile)
      OfferTimeoutJob.set(wait: OFFER_TIMEOUT).perform_later(offer)
    elsif trip.reload.searching?
      DispatchRetryJob.set(wait: RETRY_EVERY).perform_later(trip)
    end
    offer
  end

  # Offers the trip to this driver if they are still free. Called with the trip locked.
  def self.reserve(trip, driver, eta)
    DriverProfile.where(id: driver.id).lock("FOR UPDATE SKIP LOCKED").first or return
    return if Trip.busy.exists?(driver_profile_id: driver.id) || TripOffer.live.exists?(driver_profile_id: driver.id)

    trip.offers.create!(driver_profile: driver, eta_s: eta, expires_at: OFFER_TIMEOUT.from_now)
  end
  private_class_method :reserve

  def self.accept!(offer)
    trip = Trip.transaction do
      trip = offer.trip.lock!
      driver = offer.driver_profile.lock!
      offer.lock!
      raise Error, "offer_gone" unless offer.pending? && offer.expires_at.future? && trip.searching?
      raise Error, "busy" if Trip.busy.exists?(driver_profile_id: driver.id)

      offer.accepted!
      trip.update!(status: :accepted, driver_profile: driver, accepted_at: Time.current)
      trip
    end
    Notify.trip(trip)
    trip
  rescue ActiveRecord::RecordNotUnique
    raise Error, "busy"
  end

  def self.decline!(offer)
    expire!(offer, :declined)
  end

  # Called when an offer runs out (OfferTimeoutJob) or is declined: on to the next driver.
  def self.expire!(offer, status = :expired)
    changed = TripOffer.transaction do
      offer.lock!
      offer.pending? && offer.update!(status: status)
    end
    return unless changed

    Notify.driver(offer.driver_profile)
    offer_next!(offer.trip)
  end

  def self.give_up!(trip)
    updated = Trip.where(id: trip.id, status: :searching).update_all(status: Trip.statuses[:no_drivers], cancelled_by: "system", updated_at: Time.current)
    Notify.trip(trip.reload) if updated.positive?
    nil
  end
end
