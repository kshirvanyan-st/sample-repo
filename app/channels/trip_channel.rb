# Live updates for one trip: status changes and the car's position. Only its rider and driver may listen.
class TripChannel < ApplicationCable::Channel
  def subscribed
    trip = Trip.find_by(id: params[:id])
    trip&.participant?(current_user) ? stream_for(trip) : reject
  end
end
