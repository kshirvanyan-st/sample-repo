# Where the MediaMTX media server lives. Rails is only the control plane: it authorizes
# publish/read requests and tracks stream state; video never passes through Rails.
#
#   MEDIA_WEBRTC_URL  public base URL for WHIP/WHEP (browser publish + low-latency playback)
#   MEDIA_HLS_URL     public base URL for HLS playback (fallback)
#   MEDIA_RTMP_URL    RTMP ingest URL shown to OBS users
#   MEDIA_API_URL     MediaMTX control API, reachable from Rails only
#   MEDIA_HOOK_SECRET shared secret MediaMTX sends with auth requests and hooks
#   TURN_URLS / TURN_SECRET  optional coturn servers (comma-separated) and their REST API secret
Rails.application.configure do
  development_default = ->(value) { Rails.env.production? ? nil : value }

  config.x.media.webrtc_url = ENV.fetch("MEDIA_WEBRTC_URL") { development_default.("http://localhost:8889") }
  config.x.media.hls_url = ENV.fetch("MEDIA_HLS_URL") { development_default.("http://localhost:8888") }
  config.x.media.rtmp_url = ENV.fetch("MEDIA_RTMP_URL") { development_default.("rtmp://localhost:1935") }
  config.x.media.api_url = ENV.fetch("MEDIA_API_URL") { development_default.("http://localhost:9997") }
  config.x.media.hook_secret = ENV.fetch("MEDIA_HOOK_SECRET") { development_default.("development-media-secret") }
  config.x.media.turn_urls = ENV.fetch("TURN_URLS", "").split(",").map(&:strip).compact_blank
  config.x.media.turn_secret = ENV["TURN_SECRET"]
end
