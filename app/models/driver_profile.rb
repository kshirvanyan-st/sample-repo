# A user's application to drive, and once approved, their driver record.
# draft / needs_changes / suspended: the driver can edit and (re)submit.
# submitted: waiting in the admin queue. approved: may go online (Phase 4). rejected: final.
class DriverProfile < ApplicationRecord
  DOCUMENTS = %i[ license_front license_back id_document selfie ].freeze
  include DocumentAttachments

  belongs_to :user
  has_one :vehicle, dependent: :destroy
  has_many :expiry_notices, dependent: :delete_all
  has_one :location, class_name: "DriverLocation", dependent: :delete
  has_many :trips, dependent: :restrict_with_exception
  has_many :trip_offers, dependent: :delete_all
  has_many :ledger_entries, dependent: :restrict_with_exception
  has_many :top_ups, dependent: :restrict_with_exception
  accepts_nested_attributes_for :vehicle, update_only: true

  enum :status, { draft: 0, submitted: 1, needs_changes: 2, approved: 3, rejected: 4, suspended: 5 }, validate: true

  validates :license_number, length: { maximum: 30 }
  with_options on: :submit do
    validates :license_number, :license_expires_on, :vehicle, presence: true
    validate :documents_attached
    validate :license_still_valid
  end

  scope :queue, -> { submitted.order(:submitted_at) }
  scope :online, -> { where.not(online_at: nil) }

  def online?
    online_at.present?
  end

  # Raises Dispatch::Error "low_balance" while the driver owes more than the platform allows.
  def go_online!
    raise Dispatch::Error, "low_balance" unless Settlement.can_go_online?(self)

    update!(online_at: Time.current) unless online?
  end

  def go_offline!
    update!(online_at: nil)
  end

  def active_trip
    trips.busy.first
  end

  def current_offer
    trip_offers.live.includes(:trip).order(:created_at).last
  end

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
