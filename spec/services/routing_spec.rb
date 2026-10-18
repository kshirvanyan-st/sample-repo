require "rails_helper"

RSpec.describe Routing do
  let(:from) { point(Places::REPUBLIC_SQUARE) }
  let(:to) { point(Places::CASCADE) }

  describe Routing::OsrmAdapter do
    it "reads distance, time and the route line" do
      allow(HttpJson).to receive(:get).and_return(
        "code" => "Ok", "routes" => [ { "distance" => 2601.1, "duration" => 238.2, "geometry" => { "type" => "LineString", "coordinates" => [ [ 44.51, 40.17 ], [ 44.52, 40.19 ] ] } } ])
      route = described_class.new.route(from, to)
      expect(route).to have_attributes(distance_m: 2601, duration_s: 238, approximate: false)
      expect(HttpJson).to have_received(:get).with(%r{/route/v1/driving/44.5126,40.1777;44.5152,40.1913\z}, hash_including(geometries: "geojson"))
    end

    it "treats OSRM's NoRoute as a failure" do
      allow(HttpJson).to receive(:get).and_return("code" => "NoRoute")
      expect { described_class.new.route(from, to) }.to raise_error(HttpJson::Error)
    end
  end

  it "falls back to a straight-line estimate when OSRM is down" do
    allow(Rails.configuration.x.routing).to receive(:adapter).and_return(:osrm)
    allow(HttpJson).to receive(:get).and_raise(HttpJson::Error, "connection refused")
    expect(Routing.route(from, to)).to have_attributes(approximate: true)
  end

  it "routes through Yerevan's streets on a real OSRM server", :osrm do
    route = Routing::OsrmAdapter.new.route(from, to)
    expect(route.approximate).to be(false)
    expect(route.distance_m).to be_between(1_800, 4_500) # straight line is ~1.5 km
    expect(route.geometry["coordinates"].size).to be > 5
  end
end
