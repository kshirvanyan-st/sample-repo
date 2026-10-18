class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followee, class_name: "User"

  validates :followee_id, uniqueness: { scope: :follower_id }
  validate :not_self

  private
    def not_self
      errors.add(:followee, "can't be yourself") if follower_id == followee_id
    end
end
