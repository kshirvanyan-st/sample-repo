class Match < ApplicationRecord
  belongs_to :user_a, class_name: "User"
  belongs_to :user_b, class_name: "User"

  scope :for, ->(user) { where(user_a: user).or(where(user_b: user)) }

  # Pairs are stored with the lower id first so (a, b) and (b, a) hit the same unique index.
  def self.between(a, b)
    ids = [ a.id, b.id ].sort
    find_by(user_a_id: ids.first, user_b_id: ids.last)
  end

  def self.between!(a, b)
    ids = [ a.id, b.id ].sort
    create_or_find_by!(user_a_id: ids.first, user_b_id: ids.last)
  end

  def other(user)
    user_a_id == user.id ? user_b : user_a
  end
end
