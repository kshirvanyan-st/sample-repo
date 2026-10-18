require "rails_helper"

RSpec.describe Dispatch do
  include ActiveJob::TestHelper

  describe ".request!" do
    it "books at the quoted price and offers the nearest driver" do
      near = online_driver(lat: 40.1780, lon: 44.5128)
      online_driver(lat: 40.1900, lon: 44.5300)
      rider = create(:user)
      quote = quote_for(rider)

      trip = Dispatch.request!(quote: quote, vehicle_class: "economy")
      expect(trip).to have_attributes(status: "searching", fare: quote.prices["economy"], rider: rider)
      expect(trip.offers.sole).to have_attributes(driver_profile: near, status: "pending")
      expect(OfferTimeoutJob).to have_been_enqueued.with(trip.offers.sole)
    end

    it "refuses an expired quote or an unknown class" do
      quote = quote_for(create(:user))
      expect { Dispatch.request!(quote: quote, vehicle_class: "limousine") }.to raise_error(Dispatch::Error, "unknown_class")
      travel FareQuote::TTL + 1.second do
        expect { Dispatch.request!(quote: quote, vehicle_class: "economy") }.to raise_error(Dispatch::Error, "quote_expired")
      end
    end

    it "allows one open trip per rider" do
      rider = create(:user)
      book(rider)
      expect { book(rider) }.to raise_error(Dispatch::Error, "already_riding")
    end
  end

  describe ".candidates" do
    let(:trip) { book }

    it "skips drivers who can't take the ride" do
      good = online_driver
      online_driver(fresh: false)                         # stale position
      online_driver(vehicle_class: :comfort)              # wrong class
      online_driver(lat: 40.30, lon: 44.70)               # over 5 km away
      online_driver.tap(&:go_offline!)                    # offline
      online_driver.tap { |driver| driver.user.update!(banned_at: Time.current) }
      online_driver.tap { |driver| driver.update!(status: :suspended) }
      busy = online_driver
      create(:trip_on_the_way, driver_profile: busy)

      Trip.where(id: trip.id).update_all(status: :searching)
      trip.offers.delete_all
      expect(Dispatch.candidates(trip.reload)).to contain_exactly(good)
    end

    it "skips drivers already offered this trip, or looking at another offer" do
      first = online_driver
      trip = book
      expect(trip.offers.sole.driver_profile).to eq(first)
      expect(Dispatch.candidates(trip)).to be_empty
      expect(Dispatch.candidates(book)).to be_empty
    end
  end

  it "ranks the nearby drivers by driving time, not distance" do
    near = online_driver(lat: 40.1780, lon: 44.5128)
    quicker = online_driver(lat: 40.1820, lon: 44.5160)
    allow(Routing).to receive(:etas) { |origins, _| origins.map { |origin| origin.y.round(3) == 40.182 ? 60 : 600 } }
    expect(book.offers.sole.driver_profile).to eq(quicker)
    expect(near.trip_offers).to be_empty
  end

  it "moves on to the next driver when an offer is declined or times out" do
    first = online_driver(lat: 40.1780, lon: 44.5128)
    second = online_driver(lat: 40.1800, lon: 44.5140)
    third = online_driver(lat: 40.1850, lon: 44.5200)
    trip = book

    Dispatch.decline!(trip.offers.find_by!(driver_profile: first))
    expect(trip.offers.pending.sole.driver_profile).to eq(second)

    OfferTimeoutJob.perform_now(trip.offers.pending.sole)
    expect(trip.offers.pending.sole.driver_profile).to eq(third)
    expect(trip.offers.map(&:status)).to contain_exactly("declined", "expired", "pending")
  end

  it "keeps looking for a while, then gives up" do
    trip = book
    expect(trip.offers).to be_empty
    expect(DispatchRetryJob).to have_been_enqueued.with(trip)

    travel Dispatch::SEARCH_TIMEOUT + 1.second do
      DispatchRetryJob.perform_now(trip)
    end
    expect(trip.reload).to be_no_drivers
  end

  describe ".accept!" do
    it "assigns the driver" do
      driver = online_driver
      trip = book
      Dispatch.accept!(trip.offers.sole)
      expect(trip.reload).to have_attributes(status: "accepted", driver_profile: driver)
      expect(trip.accepted_at).to be_present
    end

    it "refuses an offer that has expired or was already taken" do
      online_driver
      trip = book
      offer = trip.offers.sole
      travel Dispatch::OFFER_TIMEOUT + 1.second do
        expect { Dispatch.accept!(offer) }.to raise_error(Dispatch::Error, "offer_gone")
      end

      offer.update!(expires_at: 1.minute.from_now)
      Dispatch.accept!(offer)
      expect { Dispatch.accept!(offer.reload) }.to raise_error(Dispatch::Error, "offer_gone")
    end

    it "never gives a driver two trips" do
      driver = online_driver
      first = book
      Dispatch.accept!(first.offers.sole)

      second = book
      stray = second.offers.create!(driver_profile: driver, expires_at: 1.minute.from_now) # bypassing the dispatcher
      expect { Dispatch.accept!(stray) }.to raise_error(Dispatch::Error, "busy")
      expect(second.reload).to be_searching
    end
  end
end
