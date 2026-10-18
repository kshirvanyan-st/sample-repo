module Geocoding
  class NominatimAdapter
    VIEWBOX = Geo::ARMENIA.values_at(:min_lon, :max_lat, :max_lon, :min_lat).join(",")

    def search(query, locale:)
      results = get("search", q: query, countrycodes: "am", viewbox: VIEWBOX, bounded: 1, limit: 6, addressdetails: 1, "accept-language": locale)
      results.map { |result| place(result) }
    end

    def reverse(point, locale:)
      result = get("reverse", lat: point.y, lon: point.x, zoom: 18, addressdetails: 1, "accept-language": locale)
      result["error"] ? nil : place(result)
    end

    private
      def get(path, params)
        HttpJson.get("#{Rails.configuration.x.geocoding.nominatim_url}/#{path}", params.merge(format: "jsonv2"),
          headers: { "User-Agent" => "TaxiAM/1.0 (#{ENV.fetch("APP_HOST", "development")})" })
      end

      def place(result)
        address = result["address"] || {}
        street = [ address["road"], address["house_number"] ].compact.join(" ").presence
        name = result["name"].presence || street || result["display_name"].to_s.split(",").first
        details = [ street, address["suburb"] || address["city_district"] ].compact.uniq - [ name ]
        Place.new(name: name, address: details.join(", ").presence || result["display_name"].to_s.split(", ").drop(1).first(2).join(", "),
          lat: result["lat"].to_f, lon: result["lon"].to_f)
      end
  end
end
