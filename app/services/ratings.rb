# Both sides rate each other after a trip. Averages use the last WINDOW ratings, so drivers who
# improve aren't held back by their first week; a driver who falls below REVIEW_BELOW is flagged for a
# person to review (never suspended automatically).
module Ratings
  WINDOW = 30
  REVIEW_BELOW = 4.5
  REVIEW_MIN_COUNT = 10
  RATE_WITHIN = 7.days
  NEW_DRIVER_SCORE = 4.8 # used by dispatch until a driver has MIN_FOR_SCORE ratings
  MIN_FOR_SCORE = 5

  REASONS = {
    rider_rates_driver: { low: %w[ unsafe_driving rude dirty_car wrong_route late ], high: %w[ friendly clean_car smooth_driving ] },
    driver_rates_rider: { low: %w[ rude late messy ], high: %w[ polite on_time ] }
  }.freeze

  class Error < Dispatch::Error; end

  def self.role_for(trip, user)
    if user && trip.rider_id == user.id then :rider_rates_driver
    elsif user && trip.driver&.id == user.id then :driver_rates_rider
    end
  end

  def self.rated?(trip, role)
    Rating.exists?(trip: trip, role: role)
  end

  def self.pending?(trip, user)
    (role = role_for(trip, user)) && trip.completed? && trip.completed_at > RATE_WITHIN.ago && !rated?(trip, role)
  end

  def self.submit!(trip:, rater:, stars:, reasons: [], comment: nil)
    role = role_for(trip, rater) or raise Error, "not_allowed"
    raise Error, "too_late" unless trip.completed? && trip.completed_at > RATE_WITHIN.ago

    ratee = role == :rider_rates_driver ? trip.driver : trip.rider
    rating = Rating.transaction do
      Rating.create!(trip: trip, rater: rater, ratee: ratee, role: role, stars: stars.to_i,
        reasons: Array(reasons).compact_blank.uniq, comment: comment.to_s.strip.first(500).presence).tap { recompute!(ratee, role) }
    end
    if rating.rider_rates_driver? && rating.stars == 1 && rating.reasons.include?("unsafe_driving")
      Support.open!(user: rater, trip: trip, kind: :safety, body: rating.comment || I18n.t("ratings.unsafe_report"))
    end
    rating
  rescue ActiveRecord::RecordNotUnique
    raise Error, "already_rated"
  rescue ActiveRecord::RecordInvalid
    raise Error, "bad_rating"
  end

  def self.recompute!(ratee, role)
    scope = Rating.where(ratee: ratee, role: role)
    recent = scope.order(created_at: :desc).limit(WINDOW).pluck(:stars)
    average = (recent.sum.to_d / recent.size).round(2)
    if role == :rider_rates_driver
      driver = ratee.driver_profile
      driver.update!(rating_avg: average, rating_count: scope.count)
      flag_for_review!(driver) if driver.rating_count >= REVIEW_MIN_COUNT && average < REVIEW_BELOW && driver.review_flagged_at.nil?
    else
      ratee.update!(rider_rating_avg: average, rider_rating_count: scope.count)
    end
  end

  def self.flag_for_review!(driver)
    driver.update!(review_flagged_at: Time.current)
    ModerationAction.create!(moderator: nil, user: driver.user, action: "flag_for_review",
      details: { driver_profile_id: driver.id, rating_avg: driver.rating_avg.to_f })
  end

  # Dispatch's tie-break: higher-rated drivers first among those this close in arrival time.
  def self.dispatch_score(driver)
    driver.rating_count >= MIN_FOR_SCORE && driver.rating_avg ? driver.rating_avg.to_f : NEW_DRIVER_SCORE
  end
end
