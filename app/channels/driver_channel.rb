# The driver app's live line: "refresh" nudges when an offer or trip changes, and the driver's
# position coming in every few seconds while online.
class DriverChannel < ApplicationCable::Channel
  MIN_INTERVAL = 1.second

  def subscribed
    @driver = current_user.driver_profile
    @driver&.approved? ? stream_for(@driver) : reject
  end

  def location(data)
    return if @last_at && @last_at > MIN_INTERVAL.ago
    return unless (point = Geo.point(lat: data["lat"], lon: data["lon"]))

    @last_at = Time.current
    heading = Float(data["heading"], exception: false)
    DriverLocation.record!(@driver, point, heading: heading, speed: Float(data["speed"], exception: false))
    if (trip = @driver.active_trip)
      trip.points.create!(location: point, recorded_at: Time.current)
      Notify.location(trip, point, heading)
    end
  end
end
