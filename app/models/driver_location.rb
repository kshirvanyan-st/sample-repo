# The latest position of a driver. Positions older than FRESH are never used for dispatch.
class DriverLocation < ApplicationRecord
  FRESH = 60.seconds

  belongs_to :driver_profile

  scope :fresh, -> { where(recorded_at: FRESH.ago..) }

  def self.record!(driver_profile, point, heading: nil, speed: nil)
    upsert({ driver_profile_id: driver_profile.id, location: point, heading: heading, speed: speed, recorded_at: Time.current },
      unique_by: :driver_profile_id)
  end

  def fresh?
    recorded_at >= FRESH.ago
  end
end
