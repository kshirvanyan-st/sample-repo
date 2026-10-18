class Like < ApplicationRecord
  belongs_to :liker, class_name: "User"
  belongs_to :likee, class_name: "User"

  enum :kind, { skip: 0, like: 1, superlike: 2 }, validate: true

  scope :positive, -> { where(kind: %i[ like superlike ]) }

  validates :likee_id, uniqueness: { scope: :liker_id }
  validate :not_self

  # Runs after commit so that when two people like each other at the same moment,
  # whichever commits second still sees the other's like.
  after_create_commit :match_if_mutual

  def positive?
    like? || superlike?
  end

  private
    def not_self
      errors.add(:likee, "can't be yourself") if liker_id == likee_id
    end

    def match_if_mutual
      return unless positive? && Like.positive.exists?(liker: likee, likee: liker)

      Match.between!(liker, likee)
    end
end
