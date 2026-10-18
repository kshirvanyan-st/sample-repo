# MediaMTX's HTTP auth callback (authMethod: http). MediaMTX POSTs JSON describing
# who wants to do what ({ action, path, protocol, user, password, token, query, ip })
# and allows the action only on a 2xx response.
class Media::AuthController < Media::BaseController
  def create
    allowed = case payload["action"]
    when "publish" then authorize_publish
    when "read" then authorize_read
    when "api" then authorize_api
    else false
    end

    head(allowed ? :ok : :unauthorized)
  end

  private
    # The JSON body; `params` can't be used because Rails' own "action" key shadows MediaMTX's.
    def payload
      request.request_parameters
    end

    # The secret sent by the client: a Bearer token (WHIP/WHEP), a password, or ?token= (RTMP/HLS).
    def credential
      payload["token"].presence || payload["password"].presence || Rack::Utils.parse_query(payload["query"].to_s)["token"].to_s
    end

    def broadcaster
      @broadcaster ||= Stream.broadcaster_for_path(payload["path"])
    end

    def authorize_publish
      return false unless broadcaster&.onboarded? && broadcaster.stream_key.present?
      return false unless ActiveSupport::SecurityUtils.secure_compare(credential, broadcaster.stream_key)

      # Publishing straight from OBS without the Go Live page opens a stream with a default title.
      stream = broadcaster.open_stream || broadcaster.streams.create!(title: "#{broadcaster.profile.display_name} is live")
      stream.update!(ingest_protocol: payload["protocol"])
      true
    rescue ActiveRecord::RecordNotUnique
      true # another request opened the stream at the same moment
    end

    # Rails' own calls to the MediaMTX control API (MediaServer).
    def authorize_api
      ActiveSupport::SecurityUtils.secure_compare(payload["password"].to_s, Rails.configuration.x.media.hook_secret.to_s)
    end

    def authorize_read
      stream = broadcaster&.live_stream
      stream.present? && stream.readable_with?(credential)
    end
end
