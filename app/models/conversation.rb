class Conversation < ApplicationRecord
  belongs_to :match
  has_many :messages, -> { order(:created_at, :id) }, dependent: :delete_all, inverse_of: :conversation

  scope :for, ->(user) { joins(:match).merge(Match.for(user)) }
  scope :recent_first, -> { order(Arel.sql("conversations.last_message_at DESC NULLS LAST, conversations.created_at DESC")) }

  delegate :other, to: :match

  def self.open_for!(match)
    create_or_find_by!(match: match)
  end

  def participant?(user)
    user.id.in?([ match.user_a_id, match.user_b_id ])
  end

  def unread_for(user)
    messages.where(read_at: nil).where.not(sender: user)
  end

  # Marks the other person's messages as read and tells their open chat window.
  def mark_read_by!(user)
    return if unread_for(user).update_all(read_at: Time.current).zero?

    broadcast_update_to self, target: "read_receipt", html: "Seen"
    Message.broadcast_unread_count(user)
  end
end
