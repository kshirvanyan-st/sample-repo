# The prices a rider saw for a route. Phase 4 books a ride from a quote while it is valid.
class FareQuote < ApplicationRecord
  TTL = 10.minutes

  belongs_to :user

  validates :pickup, :dropoff, presence: true
  validate :inside_service_area, on: :create
  validate :not_the_same_place, on: :create

  scope :current, -> { where(expires_at: Time.current..) }

  # Routes the trip and prices every vehicle class. Unsaved if it fails validation.
  def self.build_for(user:, pickup:, dropoff:, pickup_address: nil, dropoff_address: nil)
    quote = new(user: user, pickup: pickup, dropoff: dropoff, pickup_address: pickup_address, dropoff_address: dropoff_address)
    return quote unless quote.valid?

    route = Routing.route(pickup, dropoff)
    tariffs = Tariff.ordered.to_a
    quote.assign_attributes(
      distance_m: route.distance_m, duration_s: route.duration_s, approximate: route.approximate,
      route: route.geometry || {},
      prices: tariffs.to_h { |tariff| [ tariff.vehicle_class, tariff.fare_for(distance_m: route.distance_m, duration_s: route.duration_s) ] },
      tariffs: tariffs.to_h { |tariff| [ tariff.vehicle_class, tariff.snapshot ] },
      expires_at: TTL.from_now)
    quote
  end

  # Cheapest class first (jsonb doesn't keep key order).
  def prices_by_class
    prices.sort_by { |vehicle_class, _| Vehicle.vehicle_classes.fetch(vehicle_class, 99) }
  end

  def expired?
    expires_at.past?
  end

  def distance_km
    (distance_m / 1000.0).round(1)
  end

  def duration_min
    (duration_s / 60.0).ceil
  end

  private
    def inside_service_area
      errors.add(:base, :outside_service_area) if pickup && dropoff && !ServiceZone.serves?(pickup, dropoff)
    end

    def not_the_same_place
      errors.add(:base, :same_place) if pickup && dropoff && Geo.distance_m(pickup, dropoff) < 100
    end
end
