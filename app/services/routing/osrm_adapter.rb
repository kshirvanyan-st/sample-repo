module Routing
  class OsrmAdapter
    def route(from, to)
      coordinates = [ from, to ].map { |point| "#{point.x},#{point.y}" }.join(";")
      data = HttpJson.get("#{Rails.configuration.x.routing.osrm_url}/route/v1/driving/#{coordinates}", { overview: "full", geometries: "geojson" })
      raise HttpJson::Error, "OSRM: #{data["code"]}" unless data["code"] == "Ok" && (best = data["routes"]&.first)

      Route.new(distance_m: best["distance"].round, duration_s: best["duration"].round, geometry: best["geometry"], approximate: false)
    end

    # One OSRM "table" request: every origin to the destination (the last coordinate).
    def etas(origins, destination)
      coordinates = [ *origins, destination ].map { |point| "#{point.x},#{point.y}" }.join(";")
      data = HttpJson.get("#{Rails.configuration.x.routing.osrm_url}/table/v1/driving/#{coordinates}",
        { sources: (0...origins.size).to_a.join(";"), destinations: origins.size, annotations: "duration" }, timeout: 3)
      raise HttpJson::Error, "OSRM: #{data["code"]}" unless data["code"] == "Ok"

      fallback = StraightLineAdapter.new
      data["durations"].each_with_index.map do |(seconds), index|
        seconds ? seconds.round : fallback.etas([ origins[index] ], destination).first # nil: no road connection found
      end
    end
  end
end
