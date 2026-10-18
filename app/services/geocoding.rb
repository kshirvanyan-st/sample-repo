# Address search and reverse geocoding (config.x.geocoding), limited to Armenia and cached for a day.
# The public Nominatim server forbids autocomplete, so the app searches only when the rider asks.
module Geocoding
  Place = Data.define(:name, :address, :lat, :lon) do
    def point
      Geo.point(lat: lat, lon: lon)
    end
  end

  ADAPTERS = { nominatim: "Geocoding::NominatimAdapter", test: "Geocoding::TestAdapter" }.freeze

  def self.search(query, locale: I18n.locale)
    query = query.to_s.squish.first(120)
    return [] if query.length < 2

    Rails.cache.fetch([ "geocode", locale, query.downcase ], expires_in: 1.day) { adapter.search(query, locale: locale.to_s) }
  end

  def self.reverse(point, locale: I18n.locale)
    key = [ "reverse-geocode", locale, point.y.round(5), point.x.round(5) ]
    Rails.cache.fetch(key, expires_in: 1.day) { adapter.reverse(point, locale: locale.to_s) }
  end

  def self.adapter
    ADAPTERS.fetch(Rails.configuration.x.geocoding.adapter.to_sym).constantize.new
  end
end
