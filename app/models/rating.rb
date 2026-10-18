class Rating < ApplicationRecord
  belongs_to :trip
  belongs_to :rater, class_name: "User"
  belongs_to :ratee, class_name: "User"

  enum :role, { rider_rates_driver: 0, driver_rates_rider: 1 }, validate: true

  validates :stars, numericality: { only_integer: true, in: 1..5 }
  validates :comment, length: { maximum: 500 }
  validate :reasons_known

  private
    def reasons_known
      errors.add(:reasons, :inclusion) unless (reasons - Ratings::REASONS.fetch(role.to_s.to_sym, {}).values.flatten).empty?
    end
end
