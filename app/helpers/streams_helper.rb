module StreamsHelper
  TURN_CREDENTIAL_TTL = 12.hours

  # ICE servers for WebRTC. TURN credentials use coturn's REST API scheme
  # (use-auth-secret): username "<expiry>:<user id>", password HMAC-SHA1 of it.
  def media_ice_servers
    media = Rails.configuration.x.media
    return [] if media.turn_urls.empty? || media.turn_secret.blank?

    username = "#{TURN_CREDENTIAL_TTL.from_now.to_i}:#{Current.user.id}"
    credential = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA1", media.turn_secret, username))
    [ { urls: media.turn_urls, username: username, credential: credential } ]
  end

  def stream_duration(stream)
    seconds = stream.duration.to_i
    format("%d:%02d:%02d", seconds / 3600, seconds % 3600 / 60, seconds % 60)
  end

  def live_badge(classes = "")
    tag.span("● LIVE", class: "rounded bg-red-600 text-white text-xs font-bold px-2 py-0.5 #{classes}")
  end
end
