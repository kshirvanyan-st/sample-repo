require "rails_helper"

RSpec.describe "Admin tariffs and zones", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:economy) { Tariff.economy.first }

  it "is only for admins" do
    sign_in_as(create(:user, :dispatcher))
    patch admin_tariff_path(economy), params: { tariff: { per_km: 1 } }
    expect(response).to have_http_status(:not_found)
    expect(economy.reload.per_km).to eq(100)
  end

  context "as an admin" do
    before { sign_in_as(admin) }

    it "changes a tariff and records who did it" do
      get admin_tariffs_path
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(economy))

      patch admin_tariff_path(economy), params: { tariff: { base_fare: 600, per_km: 120, per_minute: 15, minimum_fare: 700 } }
      expect(economy.reload).to have_attributes(base_fare: 600, per_km: 120, updated_by: admin)
    end

    it "refuses a negative tariff" do
      patch admin_tariff_path(economy), params: { tariff: { per_km: -5 } }
      expect(economy.reload.per_km).to eq(100)
      expect(flash[:alert]).to be_present
    end

    it "redraws a zone from GeoJSON" do
      zone = ServiceZone.first
      square = { type: "Polygon", coordinates: [ [ [ 44.50, 40.17 ], [ 44.52, 40.17 ], [ 44.52, 40.19 ], [ 44.50, 40.19 ], [ 44.50, 40.17 ] ] ] }
      patch admin_service_zone_path(zone), params: { service_zone: { name: "Kentron", active: "1", area_geojson: square.to_json } }
      expect(response).to redirect_to(admin_service_zones_path)
      expect(ServiceZone.serves?(point(Places::REPUBLIC_SQUARE))).to be(true)
      expect(ServiceZone.serves?(point(Places::CASCADE))).to be(false)
    end

    it "keeps the zone when the GeoJSON is broken" do
      zone = ServiceZone.first
      patch admin_service_zone_path(zone), params: { service_zone: { name: "Yerevan", area_geojson: "{oops" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(ServiceZone.serves?(point(Places::CASCADE))).to be(true)
    end
  end
end
