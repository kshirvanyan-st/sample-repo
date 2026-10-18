# A ride from booking to the end. Dispatch moves it from searching to accepted; TripLifecycle does the rest.
class Trip < ApplicationRecord
  BUSY = %w[ accepted arrived in_progress ].freeze # the driver is taken
  OPEN = (%w[ searching ] + BUSY).freeze           # the rider can't book another

  belongs_to :rider, class_name: "User"
  belongs_to :driver_profile, optional: true
  belongs_to :fare_quote
  has_many :offers, class_name: "TripOffer", dependent: :delete_all
  has_many :points, class_name: "TripPoint", dependent: :delete_all
  has_many :ratings, dependent: :destroy
  has_one :share_link, dependent: :destroy
  has_many :support_tickets, dependent: :nullify

  enum :status, { searching: 0, accepted: 1, arrived: 2, in_progress: 3, completed: 4, cancelled: 5, no_drivers: 6 }, validate: true
  enum :vehicle_class, Vehicle.vehicle_classes, prefix: :class, validate: true

  validates :fare, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :busy, -> { where(status: BUSY) }
  scope :open, -> { where(status: OPEN) }

  def driver
    driver_profile&.user
  end

  def vehicle
    driver_profile&.vehicle
  end

  def open?
    status.in?(OPEN)
  end

  def tariff
    Tariff.find_by(vehicle_class: vehicle_class)
  end

  # What a rider would pay to cancel right now (charged in Phase 5).
  def cancellation_fee_now
    return 0 unless (accepted? || arrived?) && accepted_at && (tariff = self.tariff)

    accepted_at < tariff.free_cancellation_minutes.minutes.ago ? tariff.cancellation_fee : 0
  end

  def participant?(user)
    user.present? && (rider_id == user.id || driver_profile&.user_id == user.id)
  end
end
