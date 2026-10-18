require "rails_helper"

RSpec.describe "Places", type: :request do
  it "needs a signed-in user" do
    get search_places_path(q: "Cascade")
    expect(response).to redirect_to(new_session_path)
  end

  context "signed in" do
    before { sign_in_as(create(:user)) }

    it "searches addresses" do
      get search_places_path(q: "Cascade")
      expect(response.parsed_body).to eq([ { "name" => "Cascade", "address" => "Tamanyan St, Kentron, Yerevan", "lat" => 40.1913, "lon" => 44.5152 } ])
    end

    it "says what's at a point" do
      get reverse_place_path(lat: 40.1778, lon: 44.5127)
      expect(response.parsed_body["name"]).to eq("Republic Square")
    end

    it "rejects bad coordinates" do
      get reverse_place_path(lat: "north", lon: 44.5)
      expect(response).to have_http_status(:bad_request)
    end

    it "answers 503 when the geocoder is down" do
      allow(Geocoding).to receive(:search).and_raise(HttpJson::Error, "timeout")
      get search_places_path(q: "Cascade")
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body["error"]).to be_present
    end
  end
end
