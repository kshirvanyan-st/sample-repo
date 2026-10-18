require "rails_helper"

RSpec.describe FareQuote, type: :model do
  let(:user) { create(:user) }

  def quote(pickup = Places::REPUBLIC_SQUARE, dropoff = Places::CASCADE)
    FareQuote.build_for(user: user, pickup: point(pickup), dropoff: point(dropoff))
  end

  it "prices every class from the route and keeps the tariffs it used" do
    fare_quote = quote
    expect(fare_quote.save).to be(true)
    expect(fare_quote.prices.keys).to contain_exactly("economy", "comfort")
    expect(fare_quote.prices["comfort"]).to be > fare_quote.prices["economy"]
    expect(fare_quote.tariffs["economy"]).to include("per_km" => 100)
    expect(fare_quote.distance_m).to be_within(400).of(2040) # straight line × 1.35 in tests
    expect(fare_quote.expires_at).to be_within(1.second).of(FareQuote::TTL.from_now)
  end

  it "lists the cheapest class first" do
    expect(quote.prices_by_class.map(&:first)).to eq(%w[ economy comfort ])
  end

  it "keeps its price when tariffs change later" do
    fare_quote = quote.tap(&:save!)
    Tariff.economy.first.update!(per_km: 1000)
    expect(fare_quote.reload.prices["economy"]).to be < 2000
  end

  it "refuses trips outside the service area" do
    fare_quote = quote(Places::REPUBLIC_SQUARE, Places::DILIJAN)
    expect(fare_quote).not_to be_valid
    expect(fare_quote.errors).to be_added(:base, :outside_service_area)
  end

  it "refuses a trip to the same place" do
    expect(quote(Places::CASCADE, Places::CASCADE).errors).to be_added(:base, :same_place)
  end

  it "marks straight-line estimates as approximate" do
    expect(quote.approximate).to be(true)
  end
end
