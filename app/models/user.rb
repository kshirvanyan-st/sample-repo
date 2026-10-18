class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :profile, dependent: :destroy

  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, inverse_of: :follower, dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: :followee_id, inverse_of: :followee, dependent: :destroy
  has_many :following, through: :active_follows, source: :followee
  has_many :followers, through: :passive_follows, source: :follower

  has_many :likes_given, class_name: "Like", foreign_key: :liker_id, inverse_of: :liker, dependent: :destroy
  has_many :likes_received, class_name: "Like", foreign_key: :likee_id, inverse_of: :likee, dependent: :destroy
  has_many :blocks_given, class_name: "Block", foreign_key: :blocker_id, inverse_of: :blocker, dependent: :destroy
  has_many :blocks_received, class_name: "Block", foreign_key: :blocked_id, inverse_of: :blocked, dependent: :destroy
  has_many :reports_filed, class_name: "Report", foreign_key: :reporter_id, inverse_of: :reporter, dependent: :destroy
  has_many :reports_received, class_name: "Report", foreign_key: :reported_id, inverse_of: :reported, dependent: :destroy
  has_many :streams, dependent: :destroy
  has_many :ledger_entries, dependent: :restrict_with_error
  has_many :purchases, dependent: :restrict_with_error
  has_many :gifts_sent, class_name: "GiftTransaction", foreign_key: :sender_id, inverse_of: :sender, dependent: :restrict_with_error
  has_many :gifts_received, class_name: "GiftTransaction", foreign_key: :recipient_id, inverse_of: :recipient, dependent: :restrict_with_error

  has_secure_token :stream_path, length: 24, on: :initialize
  has_secure_token :stream_key, length: 32, on: :initialize

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true

  # Users created before streaming existed get their credentials the first time they need them.
  def streaming_credentials!
    regenerate_stream_path if stream_path.blank?
    regenerate_stream_key if stream_key.blank?
    self
  end

  def open_stream
    streams.open.order(:created_at).last
  end

  def live_stream
    streams.live.order(:started_at).last
  end

  def onboarded?
    profile&.onboarded_at?
  end

  def follow(user)
    active_follows.create!(followee: user)
  end

  def unfollow(user)
    active_follows.find_by(followee: user)&.destroy
  end

  def following?(user)
    active_follows.exists?(followee: user)
  end

  def matches
    Match.for(self)
  end

  def matched_with?(user)
    Match.between(self, user).present?
  end

  # Everyone this user blocked or was blocked by.
  def blocked_user_ids
    Block.where(blocker_id: id).pluck(:blocked_id) | Block.where(blocked_id: id).pluck(:blocker_id)
  end

  def blocking?(user)
    blocks_given.exists?(blocked: user)
  end

  def blocked_with?(user)
    Block.where(blocker: self, blocked: user).or(Block.where(blocker: user, blocked: self)).exists?
  end
end
