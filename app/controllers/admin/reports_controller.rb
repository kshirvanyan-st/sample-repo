class Admin::ReportsController < Admin::BaseController
  def index
    @status = params[:status] == "resolved" ? :resolved : :open
    @reports = Report.where(status: @status).includes(:reporter, :resolved_by, reported: { profile: { photos: { image_attachment: :blob } } })
      .order(created_at: @status == :open ? :asc : :desc).limit(100)
    @report_counts = Report.open.group(:reported_id).count
  end

  # Dismiss without action; bans and photo removals happen on the user page.
  def update
    moderation.dismiss_report!(Report.open.find(params[:id]), note: params[:note])
    redirect_to admin_reports_path, notice: "Report dismissed.", status: :see_other
  end
end
