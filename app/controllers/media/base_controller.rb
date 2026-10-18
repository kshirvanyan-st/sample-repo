# Endpoints called by MediaMTX, not by browsers: no session, CSRF or browser checks.
# Every request must carry the shared secret (?secret= on auth, X-Media-Secret on hooks).
class Media::BaseController < ActionController::API
  before_action :verify_media_secret

  private
    def verify_media_secret
      expected = Rails.configuration.x.media.hook_secret.to_s
      given = request.headers["X-Media-Secret"].presence || params[:secret].to_s

      head :unauthorized unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(given, expected)
    end
end
