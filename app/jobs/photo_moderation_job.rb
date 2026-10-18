# Approves new photos. This is where an automated NSFW check will plug in;
# manual review arrives with the admin area in Phase 6.
class PhotoModerationJob < ApplicationJob
  queue_as :default

  def perform(photo)
    photo.approved! if photo.pending?
  end
end
