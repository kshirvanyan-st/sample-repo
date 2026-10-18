module MediaHelpers
  def media_secret
    Rails.configuration.x.media.hook_secret
  end

  # What MediaMTX POSTs to /media/auth.
  def media_auth(action:, path:, token: nil, password: nil, query: "", secret: media_secret)
    post "/media/auth?secret=#{secret}", params: { action: action, path: path, token: token.to_s, password: password.to_s,
      query: query, protocol: "rtmp", user: "", ip: "127.0.0.1" }.to_json, headers: { "Content-Type" => "application/json" }
  end

  def media_hook(event, path:, secret: media_secret)
    post "/media/hooks/#{event}", params: { path: path }, headers: { "X-Media-Secret" => secret }
  end
end

RSpec.configure do |config|
  config.include MediaHelpers, type: :request
end
