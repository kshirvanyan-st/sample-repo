# Everything the driver app shows, in one JSON document (GET /api/v1/driver/state).
class DriverState
  def initialize(driver)
    @driver = driver
  end

  def as_json(*)
    vehicle = @driver.vehicle
    {
      name: @driver.user.display_name,
      online: @driver.online?,
      balance: @driver.balance,
      needed: Settlement.needed_to_go_online(@driver),
      vehicle: vehicle && { description: vehicle.description, plate: vehicle.plate_number, vehicle_class: vehicle.vehicle_class },
      offer: offer_json(@driver.current_offer),
      trip: trip_json(@driver.active_trip),
      rate_trip: rate_json
    }
  end

  private
    def offer_json(offer)
      return unless offer

      trip = offer.trip
      { id: offer.id, expires_at: offer.expires_at.iso8601(3), seconds: Dispatch::OFFER_TIMEOUT.to_i,
        eta_min: offer.eta_s && [ (offer.eta_s / 60.0).ceil, 1 ].max, fare: trip.fare,
        distance_km: trip.fare_quote.distance_km, pickup: place(trip.pickup, trip.pickup_address),
        dropoff: place(trip.dropoff, trip.dropoff_address) }
    end

    def trip_json(trip)
      return unless trip

      { id: trip.id, status: trip.status, fare: trip.fare, rider: trip.rider.name.presence || "—",
        pickup: place(trip.pickup, trip.pickup_address), dropoff: place(trip.dropoff, trip.dropoff_address) }
    end

    # The driver's last trip, if they haven't rated the rider yet (asked for an hour after the trip).
    def rate_json
      trip = @driver.trips.completed.where(completed_at: 1.hour.ago..).order(completed_at: :desc).first
      { id: trip.id, rider: trip.rider.name.presence || "—" } if trip && Ratings.pending?(trip, @driver.user)
    end

    def place(point, address)
      { lat: point.y, lon: point.x, address: address }
    end
end
