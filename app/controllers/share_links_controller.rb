# The rider asks for a link to send to family; anyone with the link sees the trip live (SharedTripsController).
class ShareLinksController < ApplicationController
  rate_limit to: 10, within: 1.minute, by: -> { Current.user.id }

  def create
    trip = Current.user.trips.find(params[:trip_id])
    link = ShareLink.for(trip)
    render json: { url: shared_trip_url(link.token), text: t(".text", name: Current.user.display_name) }
  end
end
