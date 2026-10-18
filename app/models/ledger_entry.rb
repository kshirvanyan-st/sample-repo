# Append-only record of every change to a driver's balance. Written only by DriverWallet;
# driver_profiles.balance is a cache of the latest balance_after.
class LedgerEntry < ApplicationRecord
  belongs_to :driver_profile
  belongs_to :reference, polymorphic: true, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :kind, { commission: 0, top_up: 1, cancellation_payout: 2, adjustment: 3, refund: 4, fee_collection: 5 }, validate: true

  validates :amount, numericality: { only_integer: true, other_than: 0 }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def readonly?
    persisted?
  end

  before_destroy { raise ActiveRecord::ReadOnlyRecord, "Ledger entries can't be deleted" }
end
