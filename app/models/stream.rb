class Stream < ApplicationRecord
  PUBLISH_PATH_PREFIX = "live/".freeze
  VIEWER_TOKEN_TTL = 6.hours

  belongs_to :user
  has_many :viewers, class_name: "StreamViewer", dependent: :delete_all
  has_many :comments, -> { order(:created_at, :id) }, class_name: "StreamComment", dependent: :delete_all, inverse_of: :stream
  has_many :gift_transactions, dependent: :restrict_with_error

  enum :status, { pending: 0, live: 1, ended: 2 }
  enum :category, { just_chatting: 0, dating_talk: 1, music: 2, gaming: 3, travel: 4, other: 5 }, validate: true

  validates :title, presence: true, length: { maximum: 80 }

  scope :open, -> { where(status: %i[ pending live ]) }
  # Streams a viewer may see: not from someone blocked either way, not from a banned broadcaster.
  scope :visible_to, ->(viewer) { where.not(user_id: viewer.blocked_user_ids).where(user_id: User.active.select(:id)) }

  after_update_commit :broadcast_status, if: :saved_change_to_status?

  # The MediaMTX path for a broadcaster: live/<stream_path>.
  def self.media_path_for(user)
    "#{PUBLISH_PATH_PREFIX}#{user.streaming_credentials!.stream_path}"
  end

  # Parses "live/<stream_path>" back to its broadcaster.
  def self.broadcaster_for_path(path)
    stream_path = path.to_s.delete_prefix(PUBLISH_PATH_PREFIX)
    return if stream_path == path.to_s || stream_path.blank?

    User.find_by(stream_path: stream_path)
  end

  # The stream a publish attaches to: the one opened on the Go live page, or a new one with a
  # default title when the broadcaster starts OBS directly (or reconnects after it ended).
  def self.open_for_ingest!(broadcaster)
    broadcaster.open_stream || broadcaster.streams.create!(title: "#{broadcaster.profile.display_name} is live")
  rescue ActiveRecord::RecordNotUnique
    broadcaster.open_stream # opened by a concurrent request
  end

  def self.viewer_token_verifier
    Rails.application.message_verifier(:stream_viewer)
  end

  def media_path
    self.class.media_path_for(user)
  end

  # Short-lived token that lets one viewer read this stream from MediaMTX.
  def viewer_token_for(viewer)
    self.class.viewer_token_verifier.generate({ "stream_id" => id, "user_id" => viewer.id }, expires_in: VIEWER_TOKEN_TTL)
  end

  def readable_with?(token)
    data = self.class.viewer_token_verifier.verified(token.to_s)
    data.is_a?(Hash) && data["stream_id"] == id
  end

  # RTMP (classic OBS) carries AAC audio, which WebRTC can't play, so those streams are
  # watched over HLS. WHIP (browser or OBS 30+) sends Opus and gets sub-second WebRTC playback.
  def playback_protocol
    ingest_protocol == "rtmp" ? "hls" : "webrtc"
  end

  def go_live!
    update!(status: :live, started_at: Time.current) if pending?
    StreamLiveNotificationJob.perform_later(self)
  end

  def end!
    return if ended?

    update!(status: :ended, ended_at: Time.current, viewers_count: 0)
    viewers.delete_all
  end

  def refresh_viewer_count!
    count = viewers.distinct.count(:user_id)
    update_columns(viewers_count: count, peak_viewers: [ peak_viewers, count ].max)
    broadcast_update_later_to self, targets: ".viewer-count", html: count.to_s
  end

  def gift_coins
    gift_transactions.sum(:coins)
  end

  def duration
    return unless started_at

    (ended_at || Time.current) - started_at
  end

  private
    def broadcast_status
      broadcast_replace_to self, target: ActionView::RecordIdentifier.dom_id(self, :player), partial: "streams/player", locals: { stream: self }
      broadcast_replace_to self, target: ActionView::RecordIdentifier.dom_id(self, :studio_status), partial: "streams/studio_status", locals: { stream: self }
    end
end
