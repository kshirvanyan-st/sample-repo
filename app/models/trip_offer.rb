# A trip offered to one driver for a few seconds (Dispatch::OFFER_TIMEOUT).
class TripOffer < ApplicationRecord
  belongs_to :trip
  belongs_to :driver_profile

  enum :status, { pending: 0, accepted: 1, declined: 2, expired: 3 }, validate: true

  scope :live, -> { pending.where(expires_at: Time.current..) }

  def seconds_left
    [ (expires_at - Time.current).ceil, 0 ].max
  end
end
