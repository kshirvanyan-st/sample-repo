# Realtime pushes. Drivers get a nudge to refresh their state (DriverChannel); the rider's trip page
# gets its status panel re-rendered in the rider's language (Turbo Streams) and the driver app too.
module Notify
  def self.driver(driver_profile)
    DriverChannel.broadcast_to(driver_profile, type: "refresh")
  end

  def self.trip(trip)
    I18n.with_locale(trip.rider.locale || I18n.default_locale) do
      Turbo::StreamsChannel.broadcast_replace_to(trip, target: "trip_status", partial: "trips/status", locals: { trip: trip })
    end
    TripChannel.broadcast_to(trip, type: "status", status: trip.status)
    driver(trip.driver_profile) if trip.driver_profile
  end

  # New tickets appear in Admin → Support for everyone watching: each page refreshes itself (in its
  # viewer's language and filters, urgent first) rather than us rendering a row for all of them.
  def self.support_queue(_ticket)
    Turbo::StreamsChannel.broadcast_refresh_to(:support_queue)
  end

  def self.location(trip, point, heading)
    TripChannel.broadcast_to(trip, type: "location", lat: point.y, lon: point.x, heading: heading)
  end
end
