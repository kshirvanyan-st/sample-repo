require "rails_helper"

# PostGIS is what dispatch will rely on: check it's installed and measures real distances.
RSpec.describe "PostGIS" do
  it "measures the distance between two points in Yerevan" do
    republic_square = "ST_SetSRID(ST_MakePoint(44.5126, 40.1777), 4326)::geography"
    cascade = "ST_SetSRID(ST_MakePoint(44.5153, 40.1912), 4326)::geography"
    meters = ActiveRecord::Base.connection.select_value("SELECT ST_Distance(#{republic_square}, #{cascade})").to_f
    expect(meters).to be_within(100).of(1520)
  end
end
