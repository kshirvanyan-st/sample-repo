# Points are PostGIS geography(Point, 4326): x = longitude, y = latitude.
module Geo
  FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)
  EARTH_RADIUS_M = 6_371_000

  # Armenia, for geocoding and for sanity-checking coordinates that come from browsers.
  ARMENIA = { min_lon: 43.4, max_lon: 46.7, min_lat: 38.8, max_lat: 41.4 }.freeze

  def self.point(lat:, lon:)
    lat = Float(lat)
    lon = Float(lon)
    return unless lat.between?(-90, 90) && lon.between?(-180, 180)

    FACTORY.point(lon, lat)
  rescue ArgumentError, TypeError
    nil
  end

  def self.distance_m(from, to)
    lat1, lat2 = from.y * Math::PI / 180, to.y * Math::PI / 180
    dlat = lat2 - lat1
    dlon = (to.x - from.x) * Math::PI / 180
    a = Math.sin(dlat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon / 2)**2
    2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(a))
  end
end
