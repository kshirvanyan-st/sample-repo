class Admin::StreamsController < Admin::BaseController
  def index
    @streams = Stream.live.includes(user: :profile).order(viewers_count: :desc)
    @report_counts = Report.open.where(reported_id: @streams.map(&:user_id)).group(:reported_id).count
  end

  def shut_down
    stream = Stream.find(params[:id])
    moderation.end_stream!(stream, suspend: params[:suspend] == "1", reason: params[:reason])
    redirect_back_or_to admin_streams_path, notice: "Stream ended#{" and streaming suspended" if params[:suspend] == "1"}.", status: :see_other
  end
end
