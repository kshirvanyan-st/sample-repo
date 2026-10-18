class ExpiryNotice < ApplicationRecord
  STAGES = %w[ 30_days 7_days expired ].freeze

  belongs_to :driver_profile

  # True only the first time, so each reminder goes out once.
  def self.record!(driver_profile, document:, expires_on:, stage:)
    insert_all([ { driver_profile_id: driver_profile.id, document: document, expires_on: expires_on, stage: stage } ],
      unique_by: :index_expiry_notices_once, returning: :id).any?
  end
end
