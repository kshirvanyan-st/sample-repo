# Everything after a driver accepts. Each step checks who is asking and what state the trip is in.
module TripLifecycle
  ARRIVAL_RADIUS_M = 300

  class Error < Dispatch::Error; end

  def self.arrive!(trip, driver)
    step!(trip, driver, from: :accepted, to: :arrived, stamp: :arrived_at) do
      location = driver.location
      raise Error, "too_far" unless location&.fresh? && Geo.distance_m(location.location, trip.pickup) <= ARRIVAL_RADIUS_M
    end
  end

  def self.start!(trip, driver)
    step!(trip, driver, from: :arrived, to: :in_progress, stamp: :started_at)
  end

  def self.complete!(trip, driver)
    step!(trip, driver, from: :in_progress, to: :completed, stamp: :completed_at)
  end

  # Riders can cancel until the trip starts (with a fee after the free minutes); drivers can hand a
  # trip back before it starts, and it goes back to searching for another driver.
  def self.cancel!(trip, by:, reason: nil)
    redispatch = false
    Trip.transaction do
      trip.lock!
      case by
      when User
        raise Error, "not_allowed" unless trip.rider_id == by.id && trip.status.in?(%w[ searching accepted arrived ])

        trip.update!(status: :cancelled, cancelled_by: "rider", cancel_reason: reason, cancelled_at: Time.current,
          cancellation_fee: trip.cancellation_fee_now)
        trip.offers.pending.update_all(status: TripOffer.statuses[:expired], updated_at: Time.current)
      when DriverProfile
        raise Error, "not_allowed" unless trip.driver_profile_id == by.id && trip.status.in?(%w[ accepted arrived ])

        trip.offers.where(driver_profile: by).update_all(status: TripOffer.statuses[:declined], updated_at: Time.current)
        trip.update!(status: :searching, driver_profile: nil, accepted_at: nil, arrived_at: nil)
        redispatch = true
      end
    end
    Notify.trip(trip)
    Notify.driver(by) if by.is_a?(DriverProfile)
    Dispatch.offer_next!(trip) if redispatch
    trip
  end

  def self.step!(trip, driver, from:, to:, stamp:)
    Trip.transaction do
      trip.lock!
      raise Error, "not_allowed" unless trip.driver_profile_id == driver.id && trip.status == from.to_s

      yield if block_given?
      trip.update!(status: to, stamp => Time.current)
    end
    Notify.trip(trip)
    trip
  end
  private_class_method :step!
end
