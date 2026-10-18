class TicketMessage < ApplicationRecord
  belongs_to :support_ticket, touch: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }
end
