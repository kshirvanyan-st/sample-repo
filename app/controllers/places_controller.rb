# JSON for the map: address search and "what's at this point". Searches run only when the rider
# presses search (the public Nominatim server forbids search-as-you-type).
class PlacesController < ApplicationController
  rate_limit to: 30, within: 1.minute, by: -> { Current.user.id }, with: -> { head :too_many_requests }

  def search
    render json: Geocoding.search(params[:q]).map(&:to_h)
  end

  def reverse
    point = Geo.point(lat: params[:lat], lon: params[:lon]) or return head(:bad_request)
    render json: Geocoding.reverse(point)&.to_h || {}
  end

  rescue_from HttpJson::Error do |error|
    Rails.logger.warn "Geocoding failed: #{error.message}"
    render json: { error: t("places.unavailable") }, status: :service_unavailable
  end
end
