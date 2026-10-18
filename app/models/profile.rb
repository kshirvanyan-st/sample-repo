class Profile < ApplicationRecord
  MINIMUM_AGE = 18
  ONBOARDING_STEPS = %w[ basics about photos ].freeze

  belongs_to :user
  has_many :photos, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :profile

  enum :gender, { male: 0, female: 1, other: 2 }, validate: true
  enum :looking_for, { men: 0, women: 1, everyone: 2 }, prefix: :looking_for, validate: true

  validates :display_name, presence: true, length: { maximum: 50 }
  validates :birthdate, presence: true
  validates :city, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :adult

  def age(on: Date.current)
    return unless birthdate

    on.year - birthdate.year - (on.strftime("%m%d") < birthdate.strftime("%m%d") ? 1 : 0)
  end

  def main_photo
    photos.approved.first
  end

  def visible_photos_for(viewer)
    viewer == user ? photos : photos.approved
  end

  private
    def adult
      return unless birthdate

      errors.add(:birthdate, "shows you are under #{MINIMUM_AGE}") if birthdate > MINIMUM_AGE.years.ago.to_date
    end
end
