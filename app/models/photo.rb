class Photo < ApplicationRecord
  MAX_PER_PROFILE = 9
  MAX_SIZE = 10.megabytes
  CONTENT_TYPES = %w[ image/jpeg image/png image/webp ].freeze

  belongs_to :profile

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 200, 200 ]
    attachable.variant :card, resize_to_fill: [ 600, 800 ]
  end

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  before_validation :assign_position, on: :create
  validate :image_attached_and_acceptable
  validate :within_profile_limit, on: :create

  after_create_commit -> { PhotoModerationJob.perform_later(self) }

  # Moves this photo to the front so it becomes the profile's main photo.
  def make_main!
    transaction do
      siblings = profile.photos.where.not(id: id).to_a
      update!(position: 0)
      siblings.each.with_index(1) { |photo, index| photo.update!(position: index) }
    end
  end

  private
    def assign_position
      self.position = (profile.photos.maximum(:position) || -1) + 1 if profile
    end

    def image_attached_and_acceptable
      if !image.attached?
        errors.add(:image, "must be attached")
      elsif !image.blob.content_type.in?(CONTENT_TYPES)
        errors.add(:image, "must be a JPEG, PNG or WebP")
      elsif image.blob.byte_size > MAX_SIZE
        errors.add(:image, "must be smaller than #{MAX_SIZE / 1.megabyte} MB")
      end
    end

    def within_profile_limit
      if profile && profile.photos.count >= MAX_PER_PROFILE
        errors.add(:base, "You can upload up to #{MAX_PER_PROFILE} photos")
      end
    end
end
