require "net/http"

# Tiny client for the MediaMTX control API (v3). MediaMTX asks Rails to authorize each call,
# which only allows the shared media secret.
class MediaServer
  class Unavailable < StandardError; end

  KICK_ENDPOINTS = { "rtmpConn" => "rtmpconns", "webRTCSession" => "webrtcsessions" }.freeze

  def initialize(base_url = Rails.configuration.x.media.api_url, secret: Rails.configuration.x.media.hook_secret)
    @base_url = base_url
    @secret = secret
  end

  # Names of paths that are currently receiving video, e.g. ["live/abc..."].
  def ready_paths
    items = get("/v3/paths/list?itemsPerPage=1000").fetch("items", [])
    items.select { |item| item["ready"] }.map { |item| item["name"] }
  end

  # Disconnects whoever is publishing to a path (used when a stream is ended from Rails).
  def kick_publisher(path)
    source = get("/v3/paths/get/#{path}")["source"]
    endpoint = source && KICK_ENDPOINTS[source["type"]]
    post("/v3/#{endpoint}/kick/#{source["id"]}") if endpoint
  rescue Unavailable
    nil # nothing is publishing, or the media server is down; the reconcile job catches up
  end

  private
    def post(path)
      request(Net::HTTP::Post, path)
    end

    def get(path)
      JSON.parse(request(Net::HTTP::Get, path).body)
    rescue JSON::ParserError => e
      raise Unavailable, e.message
    end

    def request(verb, path)
      uri = URI.join(@base_url, path)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 2, read_timeout: 5) do |http|
        request = verb.new(uri.request_uri)
        request.basic_auth("rails", @secret) # checked by Media::AuthController#authorize_api
        http.request(request)
      end
      raise Unavailable, "MediaMTX API returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response
    rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      raise Unavailable, e.message
    end
end
