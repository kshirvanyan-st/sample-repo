class CoinPack < ApplicationRecord
  has_many :purchases, dependent: :restrict_with_error

  validates :name, presence: true
  validates :coins, numericality: { only_integer: true, greater_than: 0 }
  validates :bonus_coins, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 50 } # Stripe's minimum charge
  validates :currency, inclusion: { in: %w[ usd eur ] }

  scope :available, -> { where(active: true).order(:position, :price_cents) }

  def total_coins
    coins + bonus_coins
  end

  def price
    price_cents / 100.0
  end
end
