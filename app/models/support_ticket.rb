class SupportTicket < ApplicationRecord
  USER_KINDS = %w[ complaint lost_item fare other ].freeze # what riders and drivers can open themselves

  belongs_to :user
  belongs_to :trip, optional: true
  belongs_to :assignee, class_name: "User", optional: true
  has_many :messages, -> { order(:created_at, :id) }, class_name: "TicketMessage", dependent: :delete_all

  enum :kind, { sos: 0, complaint: 1, lost_item: 2, fare: 3, other: 4, safety: 5 }, validate: true
  enum :status, { open: 0, in_progress: 1, resolved: 2 }, validate: true
  enum :priority, { normal: 0, urgent: 1 }, validate: true

  scope :queue, -> { order(priority: :desc, created_at: :asc) }
  scope :unresolved, -> { where.not(status: :resolved) }

  def public_messages
    messages.where(internal: false)
  end
end
