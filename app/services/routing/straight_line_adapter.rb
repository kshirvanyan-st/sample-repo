module Routing
  # Used in tests and whenever OSRM is down: city roads are about a third longer than a straight
  # line, and traffic in Yerevan averages about 25 km/h.
  class StraightLineAdapter
    DETOUR = 1.35
    SPEED_M_PER_S = 25_000 / 3600.0

    def route(from, to)
      distance = Geo.distance_m(from, to) * DETOUR
      Route.new(distance_m: distance.round, duration_s: (distance / SPEED_M_PER_S).round,
        geometry: { "type" => "LineString", "coordinates" => [ [ from.x, from.y ], [ to.x, to.y ] ] }, approximate: true)
    end

    def etas(origins, destination)
      origins.map { |origin| route(origin, destination).duration_s }
    end
  end
end
