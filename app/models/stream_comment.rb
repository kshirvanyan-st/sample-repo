class StreamComment < ApplicationRecord
  MAX_LENGTH = 300

  belongs_to :stream
  belongs_to :user

  normalizes :body, with: ->(body) { body.strip }
  validates :body, presence: true, length: { maximum: MAX_LENGTH }
  validate :stream_is_open, on: :create

  after_create_commit -> { broadcast_append_to [ stream, :chat ], target: "stream_comments", partial: "stream_comments/stream_comment", locals: { stream_comment: self } }
  after_destroy_commit -> { broadcast_remove_to [ stream, :chat ] }

  private
    # Chat opens as soon as the stream is created ("starting soon") and closes when it ends.
    def stream_is_open
      errors.add(:base, "This stream has ended") if stream.nil? || stream.ended?
    end
end
