class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :saved_places, dependent: :destroy
  has_one :driver_profile, dependent: :destroy
  has_many :moderation_actions # audit rows are kept; the foreign key blocks deleting a user who has them

  enum :role, { rider: 0, driver: 1, dispatcher: 2, admin: 3 }, validate: true

  normalizes :phone, with: ->(phone) { User.normalize_phone(phone) || phone.strip }

  validates :phone, presence: true, uniqueness: true
  validate :phone_is_mobile
  validates :name, length: { maximum: 60 }
  validates :name, presence: true, on: :profile
  validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }, allow_nil: true

  scope :active, -> { where(banned_at: nil) }

  # E.164 ("+37491123456") for a valid mobile number, nil otherwise. Local numbers default to Armenia.
  def self.normalize_phone(raw)
    parsed = Phonelib.parse(raw.to_s.strip)
    parsed.e164 if parsed.valid? && parsed.types.intersect?(%i[ mobile fixed_or_mobile ])
  end

  def banned?
    banned_at.present?
  end

  def staff?
    dispatcher? || admin?
  end

  def display_phone
    Phonelib.parse(phone).international
  end

  def display_name
    name.presence || display_phone
  end

  private
    def phone_is_mobile
      errors.add(:phone, :invalid) if phone.present? && User.normalize_phone(phone).nil?
    end
end
