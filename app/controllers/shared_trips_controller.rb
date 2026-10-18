# The public, read-only view of a shared trip: the car on the map, the driver's first name, car,
# plate and status. Nothing about the rider, and no prices.
class SharedTripsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 60, within: 1.minute

  def show
    @link = ShareLink.find_by(token: params[:token].to_s)
    return render(:expired, status: :not_found) unless @link&.active?

    @trip = @link.trip
  end
end
