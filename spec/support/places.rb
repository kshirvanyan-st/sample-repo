module Places
  REPUBLIC_SQUARE = { lat: 40.1777, lon: 44.5126 }.freeze
  CASCADE = { lat: 40.1913, lon: 44.5152 }.freeze
  DILIJAN = { lat: 40.7406, lon: 44.8630 }.freeze

  def point(place)
    Geo.point(**place)
  end
end

RSpec.configure { |config| config.include Places }
