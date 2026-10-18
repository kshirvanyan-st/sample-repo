module DispatchHelpers
  # An approved, online driver with a fresh position (default: next to Republic Square).
  def online_driver(lat: 40.1790, lon: 44.5130, vehicle_class: :economy, fresh: true)
    profile = create(:driver_profile, :approved)
    profile.vehicle.update!(vehicle_class: vehicle_class)
    profile.update!(online_at: 5.minutes.ago)
    DriverLocation.record!(profile, Geo.point(lat: lat, lon: lon))
    profile.location.update!(recorded_at: 5.minutes.ago) unless fresh
    profile.reload
  end

  def quote_for(user, from: Places::REPUBLIC_SQUARE, to: Places::CASCADE)
    FareQuote.build_for(user: user, pickup: point(from), dropoff: point(to)).tap(&:save!)
  end

  def book(user = create(:user), vehicle_class: "economy")
    Dispatch.request!(quote: quote_for(user), vehicle_class: vehicle_class)
  end

  def move(driver, lat:, lon:)
    DriverLocation.record!(driver, Geo.point(lat: lat, lon: lon))
  end
end

RSpec.configure { |config| config.include DispatchHelpers }
