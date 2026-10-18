# Prices per vehicle class, in whole drams: base + per km + per minute, never below the minimum.
class Tariff < ApplicationRecord
  AMOUNTS = %i[ base_fare per_km per_minute minimum_fare ].freeze
  ROUND_TO = 10 # AMD; nobody carries smaller change

  belongs_to :updated_by, class_name: "User", optional: true

  enum :vehicle_class, Vehicle.vehicle_classes, validate: true

  validates :vehicle_class, uniqueness: true
  validates(*AMOUNTS, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 1_000_000 })

  scope :ordered, -> { order(:vehicle_class) }

  def fare_for(distance_m:, duration_s:)
    raw = base_fare + (per_km * distance_m / 1000.0) + (per_minute * duration_s / 60.0)
    ([ raw, minimum_fare ].max / ROUND_TO).ceil * ROUND_TO
  end

  def snapshot
    slice(*AMOUNTS)
  end
end
