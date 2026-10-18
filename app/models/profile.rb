class Profile < ApplicationRecord
  MINIMUM_AGE = 18
  MAXIMUM_AGE = 99
  SEEKS = { "men" => %w[ male ], "women" => %w[ female ], "everyone" => %w[ male female other ] }.freeze
  ONBOARDING_STEPS = %w[ basics about photos ].freeze

  belongs_to :user
  has_many :photos, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :profile

  # Finished onboarding and not banned: the profiles other people may see.
  scope :visible, -> { where.not(onboarded_at: nil).where(user_id: User.active.select(:id)) }

  enum :gender, { male: 0, female: 1, other: 2 }, validate: true
  enum :looking_for, { men: 0, women: 1, everyone: 2 }, prefix: :looking_for, validate: true

  validates :display_name, presence: true, length: { maximum: 50 }
  validates :birthdate, presence: true
  validates :city, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :age_min, :age_max, numericality: { only_integer: true, in: MINIMUM_AGE..MAXIMUM_AGE }
  validates :max_distance_km, numericality: { only_integer: true, in: 1..500 }, allow_nil: true
  validate :adult
  validate :age_range_ordered

  def age(on: Date.current)
    return unless birthdate

    on.year - birthdate.year - (on.strftime("%m%d") < birthdate.strftime("%m%d") ? 1 : 0)
  end

  # Genders this profile wants to see.
  def sought_genders
    SEEKS.fetch(looking_for)
  end

  def wants?(other)
    other.gender.in?(sought_genders)
  end

  def located?
    latitude.present? && longitude.present?
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

    def age_range_ordered
      errors.add(:age_max, "must be at least the minimum age") if age_min && age_max && age_min > age_max
    end
end
