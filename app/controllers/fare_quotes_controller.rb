# "Where to?": the rider picks a pickup and a drop-off on the map or by address, then sees the
# price for each class. Booking from a quote arrives in Phase 4.
class FareQuotesController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: :create, by: -> { Current.user.id }

  def new
    @fare_quote = FareQuote.new
    set_saved_places
  end

  def create
    pickup, dropoff = point_param(:pickup), point_param(:dropoff)
    if pickup.nil? || dropoff.nil?
      @fare_quote = FareQuote.new
      @fare_quote.errors.add(:base, :choose_both)
    else
      @fare_quote = FareQuote.build_for(user: Current.user, pickup: pickup, dropoff: dropoff,
        pickup_address: address_param(:pickup), dropoff_address: address_param(:dropoff))
      return redirect_to(@fare_quote) if @fare_quote.save
    end
    set_saved_places
    render :new, status: :unprocessable_content
  end

  def show
    @fare_quote = Current.user.fare_quotes.find(params[:id])
  end

  private
    def point_param(name)
      values = params.fetch(name, {})
      Geo.point(lat: values[:lat], lon: values[:lon]) if values.is_a?(ActionController::Parameters)
    end

    def address_param(name)
      params.dig(name, :address).to_s.squish.first(200).presence
    end

    def set_saved_places
      @saved_places = Current.user.saved_places.where.not(location: nil).ordered
    end
end
