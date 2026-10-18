class Gift < ApplicationRecord
  has_many :gift_transactions, dependent: :restrict_with_error

  validates :name, :emoji, presence: true
  validates :coins, numericality: { only_integer: true, greater_than: 0 }

  scope :available, -> { where(active: true).order(:position, :coins) }
end
