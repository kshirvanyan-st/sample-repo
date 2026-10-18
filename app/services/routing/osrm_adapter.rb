module Routing
  class OsrmAdapter
    def route(from, to)
      coordinates = [ from, to ].map { |point| "#{point.x},#{point.y}" }.join(";")
      data = HttpJson.get("#{Rails.configuration.x.routing.osrm_url}/route/v1/driving/#{coordinates}", { overview: "full", geometries: "geojson" })
      raise HttpJson::Error, "OSRM: #{data["code"]}" unless data["code"] == "Ok" && (best = data["routes"]&.first)

      Route.new(distance_m: best["distance"].round, duration_s: best["duration"].round, geometry: best["geometry"], approximate: false)
    end
  end
end
