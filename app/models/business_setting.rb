# Platform-wide money settings (one row), edited in Admin → Settings.
class BusinessSetting < ApplicationRecord
  belongs_to :updated_by, class_name: "User", optional: true

  validates :commission_percent, numericality: { only_integer: true, in: 0..50 }
  validates :min_balance, numericality: { only_integer: true, in: -100_000..0 }

  def self.current
    first || create!
  end

  # Whole drams, rounded up: the platform never under-charges by a fraction of a dram.
  def commission_on(fare)
    (fare * commission_percent / 100.0).ceil
  end
end
