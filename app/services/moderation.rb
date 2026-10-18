# Everything moderators can do, in one place, each step written to the audit log.
class Moderation
  class NotAllowed < StandardError; end

  def initialize(moderator)
    raise NotAllowed, "Only staff can moderate" unless moderator&.staff?

    @moderator = moderator
  end

  # Signs the user out everywhere, takes them off the air and out of discovery.
  def ban!(user, reason:)
    raise NotAllowed, "Staff can't be banned; change their role first" if user.staff?

    User.transaction do
      user.update!(banned_at: Time.current, ban_reason: reason)
      user.sessions.destroy_all
      user.reports_received.open.find_each { |report| close(report, :banned) }
      log(:ban, user, reason)
    end
    user.streams.open.find_each { |stream| shut_down(stream) }
  end

  def unban!(user)
    user.update!(banned_at: nil, ban_reason: nil)
    log(:unban, user)
  end

  # Ends a live stream for everyone; optionally stops the broadcaster from going live again.
  def end_stream!(stream, suspend: false, reason: nil)
    shut_down(stream)
    stream.user.update!(streaming_suspended_at: Time.current) if suspend
    log(suspend ? :end_stream_and_suspend : :end_stream, stream, reason)
  end

  def restore_streaming!(user)
    user.update!(streaming_suspended_at: nil)
    log(:restore_streaming, user)
  end

  def approve_photo!(photo)
    photo.approved!
    log(:approve_photo, photo)
  end

  def reject_photo!(photo, reason: nil)
    photo.rejected!
    log(:reject_photo, photo, reason)
  end

  def dismiss_report!(report, note: nil)
    close(report, :dismissed)
    log(:dismiss_report, report, note)
  end

  def change_role!(user, role)
    raise NotAllowed, "Only admins can change roles" unless @moderator.admin?
    raise NotAllowed, "You can't change your own role" if user == @moderator

    user.update!(role: role)
    log(:change_role, user, role.to_s)
  end

  private
    def shut_down(stream)
      MediaServer.new.kick_publisher(stream.media_path) if stream.live?
      stream.end!
    end

    def close(report, resolution)
      report.update!(status: :resolved, resolution: resolution, resolved_by: @moderator, resolved_at: Time.current)
    end

    def log(action, target, note = nil)
      ModerationAction.create!(moderator: @moderator, action: action, target: target, note: note.presence)
    end
end
