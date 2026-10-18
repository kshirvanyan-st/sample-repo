# Where we take rides (Yerevan first). A trip's pickup and drop-off must both be inside an active zone.
class ServiceZone < ApplicationRecord
  validates :name, presence: true, length: { maximum: 60 }
  validates :area, presence: true

  scope :active, -> { where(active: true) }
  scope :covering, ->(point) { where("ST_Covers(area, ST_GeogFromText(?))", "SRID=4326;#{point.as_text}") }

  def self.serves?(*points)
    points.all? { |point| active.covering(point).exists? }
  end

  # GeoJSON for the admin form and the map.
  def area_geojson
    area && RGeo::GeoJSON.encode(area).to_json
  end

  def area_geojson=(json)
    geometry = RGeo::GeoJSON.decode(json, geo_factory: Geo::FACTORY)
    geometry = geometry.geometry if geometry.respond_to?(:geometry) # a Feature
    self.area = geometry.is_a?(RGeo::Feature::Polygon) ? Geo::FACTORY.multi_polygon([ geometry ]) : geometry
  rescue RGeo::Error::ParseError, JSON::ParserError, MultiJson::ParseError, NoMethodError
    errors.add(:area, :invalid)
    self.area = nil
  end
end
