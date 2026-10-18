class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User"
  belongs_to :reported, class_name: "User"

  enum :reason, { spam: 0, fake: 1, inappropriate: 2, harassment: 3, underage: 4, other: 5 }, validate: true
  enum :status, { open: 0, resolved: 1 }

  validates :details, length: { maximum: 1000 }
  validate :not_self

  private
    def not_self
      errors.add(:reported, "can't be yourself") if reporter_id == reported_id
    end
end
