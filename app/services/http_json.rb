# Small JSON GET with short timeouts, for the routing and geocoding servers.
module HttpJson
  class Error < StandardError; end

  def self.get(url, params = {}, headers: {}, timeout: 5)
    uri = URI(url)
    uri.query = URI.encode_www_form(params) if params.any?
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: timeout, read_timeout: timeout) do |http|
      http.get(uri.request_uri, { "Accept" => "application/json" }.merge(headers))
    end
    raise Error, "#{uri.host} answered #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, JSON::ParserError, Net::HTTPBadResponse => e
    raise Error, "#{uri&.host}: #{e.message}"
  end
end
