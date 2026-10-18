class RatingsController < ApplicationController
  rate_limit to: 10, within: 1.minute, by: -> { Current.user.id }

  def create
    trip = Current.user.trips.find(params[:trip_id])
    Ratings.submit!(trip: trip, rater: Current.user, stars: params[:stars], reasons: params[:reasons], comment: params[:comment])
    redirect_to trip, notice: t(".thanks")
  rescue Ratings::Error => e
    redirect_to trip, alert: t("dispatch.errors.#{e.key}")
  end
end
