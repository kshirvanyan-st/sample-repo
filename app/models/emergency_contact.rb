# People texted with the share link when the user presses SOS.
class EmergencyContact < ApplicationRecord
  LIMIT = 3

  belongs_to :user

  normalizes :phone, with: ->(phone) { User.normalize_phone(phone) || phone.strip }

  validates :name, presence: true, length: { maximum: 60 }
  validates :phone, presence: true
  validate :phone_is_mobile
  validate :within_limit, on: :create

  private
    def phone_is_mobile
      errors.add(:phone, :invalid) if phone.present? && User.normalize_phone(phone).nil?
    end

    def within_limit
      errors.add(:base, :too_many_contacts, limit: LIMIT) if user && user.emergency_contacts.count >= LIMIT
    end
end
