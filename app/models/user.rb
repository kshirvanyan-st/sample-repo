class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :profile, dependent: :destroy

  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, inverse_of: :follower, dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: :followee_id, inverse_of: :followee, dependent: :destroy
  has_many :following, through: :active_follows, source: :followee
  has_many :followers, through: :passive_follows, source: :follower

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true

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
end
