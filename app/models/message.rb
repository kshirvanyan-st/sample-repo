class Message < ApplicationRecord
  MAX_LENGTH = 2000

  belongs_to :conversation, touch: :last_message_at
  belongs_to :sender, class_name: "User"

  normalizes :body, with: ->(body) { body.strip }

  validates :body, presence: true, length: { maximum: MAX_LENGTH }
  validate :sender_in_conversation

  scope :unread_for, ->(user) {
    where(read_at: nil).where.not(sender: user).where(conversation: Conversation.for(user))
  }

  after_create_commit :broadcast_to_participants

  def recipient
    conversation.other(sender)
  end

  # Updates the unread badge in every open tab of this user.
  def self.broadcast_unread_count(user)
    Turbo::StreamsChannel.broadcast_update_to [ user, :notifications ], targets: ".chats-count", html: unread_for(user).count.nonzero?.to_s
  end

  private
    def sender_in_conversation
      errors.add(:sender, "isn't part of this conversation") if conversation && sender && !conversation.participant?(sender)
    end

    def broadcast_to_participants
      broadcast_append_to conversation, target: "messages", partial: "messages/message", locals: { message: self }
      broadcast_update_to conversation, target: "read_receipt", html: ""
      Message.broadcast_unread_count(recipient)
      broadcast_replace_to [ recipient, :notifications ], target: ActionView::RecordIdentifier.dom_id(conversation, :preview),
        partial: "conversations/preview", locals: { conversation: conversation, viewer: recipient }
    end
end
