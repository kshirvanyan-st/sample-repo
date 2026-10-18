# Append-only record of every coin and earnings movement. Written only by Wallet;
# users.coin_balance / earnings_balance are caches of the latest balance_after.
class LedgerEntry < ApplicationRecord
  belongs_to :user
  belongs_to :reference, polymorphic: true, optional: true

  enum :account, { coins: 0, earnings: 1 }
  enum :kind, { purchase: 0, gift_sent: 1, gift_received: 2, refund: 3, adjustment: 4 }

  validates :amount, numericality: { other_than: 0 }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def readonly?
    persisted?
  end

  before_destroy { raise ActiveRecord::ReadOnlyRecord, "Ledger entries can't be deleted" }
end
