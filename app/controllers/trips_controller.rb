# The rider's side of a ride: book from a quote, watch it live, cancel.
class TripsController < ApplicationController
  before_action :set_trip, only: %i[ show cancel ]
  rate_limit to: 10, within: 1.minute, only: %i[ create cancel ], by: -> { Current.user.id }

  def create
    quote = Current.user.fare_quotes.find(params[:fare_quote_id])
    redirect_to Dispatch.request!(quote: quote, vehicle_class: params[:vehicle_class].to_s)
  rescue Dispatch::Error => e
    if e.key == "already_riding" && (open = Current.user.trips.open.first)
      redirect_to open, alert: t("dispatch.errors.already_riding")
    else
      redirect_to fare_quote_path(quote), alert: t("dispatch.errors.#{e.key}")
    end
  end

  def show
  end

  def cancel
    TripLifecycle.cancel!(@trip, by: Current.user, reason: params[:reason].to_s.first(200).presence)
    redirect_to @trip, notice: t(".cancelled")
  rescue TripLifecycle::Error
    redirect_to @trip, alert: t("dispatch.errors.not_allowed")
  end

  private
    def set_trip
      @trip = Current.user.trips.includes(driver_profile: %i[ user vehicle location ]).find(params[:id])
    end
end
