class SosController < ApplicationController
  # Generous: SOS must never be blocked for someone on an active trip.
  rate_limit to: 5, within: 1.minute, by: -> { Current.user.id }

  def create
    trip = Current.user.trips.find(params[:trip_id])
    Support.sos!(trip: trip, by: Current.user, location: Geo.point(lat: params[:lat], lon: params[:lon]))
    redirect_to trip, notice: t(".sent")
  rescue Dispatch::Error
    redirect_to trip, alert: t("dispatch.errors.not_allowed")
  end
end
