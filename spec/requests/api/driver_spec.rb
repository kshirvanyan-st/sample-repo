require "rails_helper"

RSpec.describe "Driver API", type: :request do
  let!(:driver) { online_driver(lat: 40.1780, lon: 44.5128) }

  def json = response.parsed_body

  it "is for approved drivers only" do
    get api_v1_driver_state_path
    expect(response).to have_http_status(:unauthorized)

    sign_in_as(create(:user))
    get api_v1_driver_state_path
    expect(response).to have_http_status(:forbidden)
  end

  context "as a driver" do
    before { sign_in_as(driver.user) }

    it "goes online and offline" do
      post offline_api_v1_driver_state_path
      expect(json).to include("online" => false)
      post online_api_v1_driver_state_path
      expect(json).to include("online" => true, "vehicle" => hash_including("plate" => driver.vehicle.plate_number))
    end

    it "shows an offer, accepts it and drives the trip to the end" do
      trip = book
      get api_v1_driver_state_path
      offer = json["offer"]
      expect(offer).to include("fare" => trip.fare, "pickup" => hash_including("lat" => 40.1777))

      post accept_api_v1_driver_offer_path(offer["id"])
      expect(json["trip"]).to include("id" => trip.id, "status" => "accepted")
      %w[ arrive start complete ].each { |action| post "/api/v1/driver/trips/#{trip.id}/#{action}" }
      expect(trip.reload).to be_completed
      expect(json["trip"]).to be_nil
    end

    it "explains why an action isn't possible" do
      trip = book
      post accept_api_v1_driver_offer_path(trip.offers.sole)
      post offline_api_v1_driver_state_path
      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("on_trip")

      post "/api/v1/driver/trips/#{trip.id}/complete"
      expect(json["error"]).to eq("not_allowed")
    end

    it "can't touch another driver's offer or trip" do
      online_driver.tap(&:go_offline!)
      other = online_driver(lat: 40.1900, lon: 44.5300)
      driver.go_offline!
      trip = book
      offer = trip.offers.sole
      expect(offer.driver_profile).to eq(other)

      post accept_api_v1_driver_offer_path(offer)
      expect(response).to have_http_status(:not_found)
      expect(trip.reload).to be_searching
    end

    it "explains errors in the driver's language" do
      get root_path(locale: "en") # remembered in the locale cookie
      DriverWallet.new(driver).debit!(5000, kind: :adjustment, note: "test")
      driver.go_offline!
      post online_api_v1_driver_state_path
      expect(response.parsed_body).to include("error" => "low_balance", "message" => "Top up your balance to go online.")
    end

    it "serves the app shell" do
      get driver_app_path
      expect(response.body).to include('id="driver-app"', "data-strings")
    end
  end
end
