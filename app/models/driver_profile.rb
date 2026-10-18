# A user's application to drive, and once approved, their driver record.
# draft / needs_changes / suspended: the driver can edit and (re)submit.
# submitted: waiting in the admin queue. approved: may go online (Phase 4). rejected: final.
class DriverProfile < ApplicationRecord
  DOCUMENTS = %i[ license_front license_back id_document selfie ].freeze
  include DocumentAttachments

  belongs_to :user
  has_one :vehicle, dependent: :destroy
  has_many :expiry_notices, dependent: :delete_all
  accepts_nested_attributes_for :vehicle, update_only: true

  enum :status, { draft: 0, submitted: 1, needs_changes: 2, approved: 3, rejected: 4, suspended: 5 }, validate: true

  validates :license_number, length: { maximum: 30 }
  with_options on: :submit do
    validates :license_number, :license_expires_on, :vehicle, presence: true
    validate :documents_attached
    validate :license_still_valid
  end

  scope :queue, -> { submitted.order(:submitted_at) }

  def editable?
    draft? || needs_changes? || suspended?
  end

  def submit!
    self.status = :submitted
    self.submitted_at = Time.current
    save!(context: :submit)
  end

  # [document name, last valid day] for everything that expires.
  def expiring_documents
    [ [ "license", license_expires_on ],
      [ "registration", vehicle&.registration_expires_on ],
      [ "insurance", vehicle&.insurance_expires_on ] ]
  end

  private
    def license_still_valid
      errors.add(:license_expires_on, :expired) if license_expires_on&.past?
    end
end
