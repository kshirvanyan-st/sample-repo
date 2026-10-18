# Staff actions on users. Each one writes a ModerationAction audit row in the same transaction.
module Moderation
  class InvalidTransition < StandardError; end

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

  # Driver applications. Each decision also texts the driver (DriverStatusSmsJob).
  def self.approve_driver!(profile, by:)
    decide!(profile, by, "approve_driver", from: %w[ submitted suspended ], status: :approved, approved_at: Time.current, review_note: nil) do
      profile.user.update!(role: :driver) if profile.user.rider?
    end
  end

  def self.request_driver_changes!(profile, by:, note:)
    decide!(profile, by, "request_driver_changes", from: %w[ submitted approved ], note: note, status: :needs_changes, review_note: note)
  end

  def self.reject_driver!(profile, by:, note:)
    decide!(profile, by, "reject_driver", from: %w[ submitted ], note: note, status: :rejected, review_note: note)
  end

  # by: nil when the system suspends (e.g. DocumentExpiryJob).
  def self.suspend_driver!(profile, note:, by: nil)
    decide!(profile, by, "suspend_driver", from: %w[ approved ], note: note, status: :suspended, review_note: note)
  end

  def self.decide!(profile, moderator, action, from:, note: nil, **changes)
    DriverProfile.transaction do
      profile.lock!
      raise InvalidTransition, "can't #{action} a #{profile.status} application" unless profile.status.in?(from)

      profile.update!(changes)
      yield if block_given?
      log!(moderator, profile.user, action, **{ driver_profile_id: profile.id, note: note }.compact)
    end
    DriverStatusSmsJob.perform_later(profile)
  end
  private_class_method :decide!

  def self.log!(moderator, user, action, **details)
    ModerationAction.create!(moderator: moderator, user: user, action: action, details: details)
  end
  private_class_method :log!
end
