module Geocoding
  # A few well-known places, so specs and offline development need no geocoding server.
  class TestAdapter
    PLACES = [
      Place.new(name: "Republic Square", address: "Kentron, Yerevan", lat: 40.1777, lon: 44.5126),
      Place.new(name: "Cascade", address: "Tamanyan St, Kentron, Yerevan", lat: 40.1913, lon: 44.5152),
      Place.new(name: "Zvartnots International Airport", address: "Zvartnots", lat: 40.1473, lon: 44.3959),
      Place.new(name: "Dilijan", address: "Tavush", lat: 40.7406, lon: 44.8630)
    ].freeze

    def search(query, locale:)
      PLACES.select { |place| place.name.downcase.include?(query.downcase) }
    end

    def reverse(point, locale:)
      PLACES.min_by { |place| Geo.distance_m(point, place.point) }
    end
  end
end
