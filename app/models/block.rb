class Block < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :blocked_id, uniqueness: { scope: :blocker_id }
  validate :not_self

  after_create_commit :sever_connections

  private
    def not_self
      errors.add(:blocked, "can't be yourself") if blocker_id == blocked_id
    end

    # Likes stay so the blocked person never comes back into the deck.
    def sever_connections
      Match.between(blocker, blocked)&.destroy
      Follow.where(follower: blocker, followee: blocked).or(Follow.where(follower: blocked, followee: blocker)).destroy_all
    end
end
