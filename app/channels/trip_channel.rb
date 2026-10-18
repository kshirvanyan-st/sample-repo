# Live updates for one trip: status changes and the car's position. Only its rider and driver may listen.
class TripChannel < ApplicationCable::Channel
  # Sent on subscribe, so a page rendered just before a change (e.g. the driver accepting) catches up.
  def self.sync(trip)
    car = trip.driver_profile&.location if trip.status.in?(Trip::BUSY)
    { type: "sync", status: trip.status, lat: car&.location&.y, lon: car&.location&.x }
  end

  def subscribed
    trip = Trip.find_by(id: params[:id])
    return reject unless trip&.participant?(current_user)

    stream_for(trip)
    transmit(self.class.sync(trip))
  end
end
