# Audit log of staff actions (bans, photo decisions, ended streams, report resolutions).
class ModerationAction < ApplicationRecord
  belongs_to :moderator, class_name: "User"
  belongs_to :target, polymorphic: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
end
