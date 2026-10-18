require "rails_helper"

RSpec.describe ServiceZone, type: :model do
  it "serves Yerevan but not Dilijan" do
    expect(ServiceZone.serves?(point(Places::REPUBLIC_SQUARE), point(Places::CASCADE))).to be(true)
    expect(ServiceZone.serves?(point(Places::REPUBLIC_SQUARE), point(Places::DILIJAN))).to be(false)
  end

  it "ignores inactive zones" do
    ServiceZone.update_all(active: false)
    expect(ServiceZone.serves?(point(Places::REPUBLIC_SQUARE))).to be(false)
  end

  it "reads and writes its area as GeoJSON" do
    zone = ServiceZone.new(name: "Test")
    zone.area_geojson = { type: "Polygon", coordinates: [ [ [ 44.0, 40.0 ], [ 44.1, 40.0 ], [ 44.1, 40.1 ], [ 44.0, 40.0 ] ] ] }.to_json
    zone.save!
    expect(JSON.parse(zone.reload.area_geojson)["type"]).to eq("MultiPolygon")
  end

  it "flags GeoJSON it can't read" do
    zone = ServiceZone.new(name: "Test")
    zone.area_geojson = "not json"
    expect(zone.errors).to be_added(:area, :invalid)
    expect(zone.area).to be_nil
  end
end
