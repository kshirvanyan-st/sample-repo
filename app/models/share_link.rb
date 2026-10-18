# A read-only live view of one trip, for whoever the rider sends the link to.
class ShareLink < ApplicationRecord
  AFTER_END = 1.hour

  belongs_to :trip

  has_secure_token :token, length: 32

  def self.for(trip)
    find_or_create_by!(trip: trip)
  end

  def active?
    return true if trip.open?

    ended_at = trip.completed_at || trip.cancelled_at || trip.updated_at
    ended_at > AFTER_END.ago
  end
end
