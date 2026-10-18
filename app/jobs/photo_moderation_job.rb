# Decides what happens to a new photo. With PHOTO_MODERATION=manual photos stay pending
# (visible only to their owner) until a moderator approves them in /admin/photos; otherwise
# they're approved automatically. This is also where an automated NSFW check would plug in.
class PhotoModerationJob < ApplicationJob
  queue_as :default

  def perform(photo)
    return if Rails.configuration.x.moderation.manual_photo_review

    photo.approved! if photo.pending?
  end
end
