require "rails_helper"

RSpec.describe "Fare quotes", type: :request do
  let(:user) { create(:user) }

  def params_for(pickup, dropoff)
    { pickup: { lat: pickup[:lat], lon: pickup[:lon], address: "From" }, dropoff: { lat: dropoff[:lat], lon: dropoff[:lon], address: "To" } }
  end

  before { sign_in_as(user) }

  it "shows the map page" do
    get new_fare_quote_path
    expect(response.body).to include('data-controller="trip-planner"')
  end

  it "offers saved places that are on the map" do
    create(:saved_place, user: user, kind: :home, location: "POINT(44.5126 40.1777)")
    create(:saved_place, user: user, kind: :work, location: nil)
    get new_fare_quote_path
    expect(response.body).to include('data-trip-planner-name-param="Տուն"') # Home
    expect(response.body).not_to include('data-trip-planner-name-param="Աշխատանք"') # Work
  end

  it "prices a trip and shows it" do
    post fare_quotes_path, params: params_for(Places::REPUBLIC_SQUARE, Places::CASCADE)
    quote = user.fare_quotes.last
    expect(response).to redirect_to(fare_quote_path(quote))
    follow_redirect!
    expect(response.body).to include("price_economy", "price_comfort", "From", "To")
  end

  it "explains when the trip is outside the service area" do
    post fare_quotes_path, params: params_for(Places::REPUBLIC_SQUARE, Places::DILIJAN)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Երևանում")
    expect(user.fare_quotes).to be_empty
  end

  it "needs both points" do
    post fare_quotes_path, params: { pickup: { lat: "", lon: "" }, dropoff: { lat: "x", lon: "y" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "keeps quotes private" do
    other = FareQuote.build_for(user: create(:user), pickup: point(Places::REPUBLIC_SQUARE), dropoff: point(Places::CASCADE)).tap(&:save!)
    get fare_quote_path(other)
    expect(response).to have_http_status(:not_found)
  end
end
