# Staff actions on users. Each one writes a ModerationAction audit row in the same transaction.
module Moderation
  def self.change_role!(user, to:, by:)
    User.transaction do
      from = user.role
      user.update!(role: to)
      log!(by, user, "change_role", from: from, to: user.role)
    end
  end

  def self.ban!(user, by:)
    User.transaction do
      user.update!(banned_at: Time.current)
      user.sessions.destroy_all
      log!(by, user, "ban")
    end
  end

  def self.unban!(user, by:)
    User.transaction do
      user.update!(banned_at: nil)
      log!(by, user, "unban")
    end
  end

  def self.log!(moderator, user, action, **details)
    ModerationAction.create!(moderator: moderator, user: user, action: action, details: details)
  end
  private_class_method :log!
end
