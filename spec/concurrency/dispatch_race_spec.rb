require "rails_helper"

# 20 riders book at once with 5 drivers online, and every driver double-taps "Accept".
# Runs with real threads and real commits (no test transaction), so it lives in its own CI job:
#   RAILS_MAX_THREADS=25 bin/rspec --tag concurrency
RSpec.describe "Dispatch and money under load", :concurrency do
  include ActiveJob::TestHelper

  self.use_transactional_tests = false

  after do
    ActiveRecord::Base.connection.execute(<<~SQL)
      TRUNCATE ledger_entries, top_ups, trip_points, trip_offers, trips, fare_quotes, driver_locations, vehicles, driver_profiles,
        sessions, active_storage_attachments, active_storage_blobs, users RESTART IDENTITY CASCADE
    SQL
    MapDefaults.load! # the CASCADE also emptied tariffs and settings (they reference users)
    BusinessSetting.current
  end

  def in_threads(items)
    items.map { |item| Thread.new { ActiveRecord::Base.connection_pool.with_connection { yield item } } }.map(&:value)
  end

  it "never double-books a driver, and every request ends up with an answer" do
    drivers = 5.times.map { |i| online_driver(lat: 40.1780 + i * 0.001, lon: 44.5130) }
    quotes = 20.times.map { quote_for(create(:user)) }

    trips = in_threads(quotes) { |quote| Dispatch.request!(quote: quote, vehicle_class: "economy") }
    expect(trips.size).to eq(20)

    live = TripOffer.live.to_a
    expect(live.map(&:driver_profile_id)).to match_array(drivers.map(&:id)) # each driver holds exactly one offer
    expect(live.map(&:trip_id).uniq.size).to eq(5)

    results = in_threads(live + live) do |offer|
      Dispatch.accept!(TripOffer.find(offer.id))
      :accepted
    rescue Dispatch::Error => e
      e.key
    end
    expect(results.count(:accepted)).to eq(5)
    expect(Trip.busy.group(:driver_profile_id).count.values).to all(eq(1))
    expect(Trip.busy.count).to eq(5)

    travel Dispatch::SEARCH_TIMEOUT + 1.second do
      in_threads(Trip.searching.to_a) { |trip| DispatchRetryJob.perform_now(trip) }
    end
    expect(Trip.group(:status).count).to eq("accepted" => 5, "no_drivers" => 15)
  end

  it "keeps a driver's balance exact when money moves in parallel" do
    driver = create(:driver_profile, :approved)
    moves = 15.times.flat_map { [ 100, -70 ] }

    in_threads(moves) do |amount|
      wallet = DriverWallet.new(DriverProfile.find(driver.id))
      amount.positive? ? wallet.credit!(amount, kind: :top_up) : wallet.debit!(-amount, kind: :adjustment, note: "race")
    end

    expect(driver.reload.balance).to eq(moves.sum)
    entries = driver.ledger_entries.order(:id).pluck(:amount, :balance_after)
    expect(entries.size).to eq(30)
    running = 0
    entries.each do |amount, balance_after|
      running += amount
      expect(balance_after).to eq(running) # every entry follows the previous one: nothing lost or doubled
    end
  end
end
