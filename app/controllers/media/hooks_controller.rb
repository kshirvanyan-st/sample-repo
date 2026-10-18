# runOnAvailable / runOnUnavailable hooks from MediaMTX: a path started or stopped receiving video.
class Media::HooksController < Media::BaseController
  def ready
    Stream.open_for_ingest!(broadcaster).go_live! if broadcaster
    head :no_content
  end

  # Not ended right away: a broadcaster who reconnects within the grace period (OBS after a
  # network blip) keeps the same stream, title and chat. See StreamEndJob.
  def not_ready
    if (stream = broadcaster&.open_stream)
      StreamEndJob.set(wait: StreamEndJob::GRACE_PERIOD).perform_later(stream)
    end
    head :no_content
  end

  private
    def broadcaster
      @broadcaster ||= Stream.broadcaster_for_path(params[:path])
    end
end
