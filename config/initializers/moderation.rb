# PHOTO_MODERATION=manual: new photos wait for a moderator in /admin/photos.
Rails.application.config.x.moderation.manual_photo_review = ENV["PHOTO_MODERATION"] == "manual"
