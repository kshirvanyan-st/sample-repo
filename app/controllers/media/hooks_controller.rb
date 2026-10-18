# runOnReady / runOnNotReady hooks from MediaMTX: a path started or stopped receiving video.
class Media::HooksController < Media::BaseController
  def ready
    broadcaster&.open_stream&.go_live!
    head :no_content
  end

  def not_ready
    broadcaster&.open_stream&.end!
    head :no_content
  end

  private
    def broadcaster
      Stream.broadcaster_for_path(params[:path])
    end
end
