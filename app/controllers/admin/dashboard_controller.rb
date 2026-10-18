class Admin::DashboardController < Admin::BaseController
  def show
    @counts = {
      open_reports: Report.open.count,
      pending_photos: Photo.pending.count,
      live_streams: Stream.live.count,
      signups_today: User.where(created_at: Time.current.all_day).count,
      banned_users: User.where.not(banned_at: nil).count
    }
    @recent_actions = ModerationAction.newest_first.includes(:moderator, :target).limit(10)
  end
end
