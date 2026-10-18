class Vehicle < ApplicationRecord
  DOCUMENTS = %i[ registration_document insurance_document photo ].freeze
  include DocumentAttachments

  # Armenian plates: "35 OS 555" (current) or "123 AB 45" (older), Latin letters.
  PLATE_FORMAT = /\A\d{2,3} [A-Z]{2} \d{2,3}\z/
  COMFORT_MAX_AGE = 10 # years

  belongs_to :driver_profile

  enum :vehicle_class, { economy: 0, comfort: 1 }, validate: true

  normalizes :plate_number, with: ->(plate) { Vehicle.normalize_plate(plate) }
  normalizes :make, :model, :color, with: ->(value) { value.squish }

  validates :plate_number, format: { with: PLATE_FORMAT }, uniqueness: true, allow_blank: true
  validates :year, numericality: { only_integer: true, greater_than_or_equal_to: 1990, less_than_or_equal_to: ->(_) { Date.current.year + 1 } }, allow_nil: true
  validates :make, :model, :color, length: { maximum: 40 }
  with_options on: :submit do
    validates :make, :model, :color, :year, :plate_number, :registration_expires_on, :insurance_expires_on, presence: true
    validate :documents_attached
    validate :papers_still_valid
    validate :new_enough_for_comfort
  end

  def self.normalize_plate(raw)
    # Cyrillic letters that look like Latin ones become Latin, for people typing on a Russian keyboard.
    compact = raw.to_s.upcase.gsub(/[[:space:]-]/, "").tr("АВЕКМНОРСТУХ", "ABEKMHOPCTYX")
    (match = compact.match(/\A(\d{2,3})([A-Z]{2})(\d{2,3})\z/)) ? match.captures.join(" ") : compact
  end

  def description
    [ color, make, model, year ].compact_blank.join(" ")
  end

  private
    def papers_still_valid
      errors.add(:registration_expires_on, :expired) if registration_expires_on&.past?
      errors.add(:insurance_expires_on, :expired) if insurance_expires_on&.past?
    end

    def new_enough_for_comfort
      errors.add(:vehicle_class, :too_old_for_comfort, years: COMFORT_MAX_AGE) if comfort? && year && year < Date.current.year - COMFORT_MAX_AGE
    end
end
