require "rails_helper"

RSpec.describe "Trips", type: :request do
  let(:rider) { create(:user) }

  before do
    online_driver
    sign_in_as(rider)
  end

  it "books from a quote and shows the live trip page" do
    quote = quote_for(rider)
    post trips_path, params: { fare_quote_id: quote.id, vehicle_class: "economy" }
    trip = rider.trips.sole
    expect(response).to redirect_to(trip_path(trip))
    follow_redirect!
    expect(response.body).to include('id="trip_status"', 'data-controller="trip-tracker"')
  end

  it "won't book from someone else's quote" do
    other = quote_for(create(:user))
    post trips_path, params: { fare_quote_id: other.id, vehicle_class: "economy" }
    expect(response).to have_http_status(:not_found)
  end

  it "sends the rider back to the price when the quote has expired" do
    quote = quote_for(rider)
    travel FareQuote::TTL + 1.second do
      post trips_path, params: { fare_quote_id: quote.id, vehicle_class: "economy" }
    end
    expect(response).to redirect_to(fare_quote_path(quote))
    expect(rider.trips).to be_empty
  end

  it "takes a rider with an open trip back to it" do
    trip = book(rider)
    get new_fare_quote_path
    expect(response).to redirect_to(trip_path(trip))
  end

  it "cancels" do
    trip = book(rider)
    post cancel_trip_path(trip)
    expect(trip.reload).to be_cancelled
  end

  it "keeps trips private" do
    other = book
    get trip_path(other)
    expect(response).to have_http_status(:not_found)
  end
end
