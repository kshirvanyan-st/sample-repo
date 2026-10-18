# Audit log of staff actions. Rows are only ever inserted.
class ModerationAction < ApplicationRecord
  belongs_to :moderator, class_name: "User", optional: true # nil: done by the system
  belongs_to :user

  validates :action, presence: true

  def readonly?
    persisted?
  end
end
