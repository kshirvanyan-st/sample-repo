require "rails_helper"

RSpec.describe TripLifecycle do
  include ActiveJob::TestHelper

  let!(:driver) { online_driver(lat: 40.1780, lon: 44.5128) }
  let(:trip) { book.tap { |trip| Dispatch.accept!(trip.offers.sole) }.reload }

  it "runs a trip from pickup to drop-off" do
    TripLifecycle.arrive!(trip, driver)
    TripLifecycle.start!(trip, driver)
    TripLifecycle.complete!(trip, driver)
    expect(trip.reload).to have_attributes(status: "completed")
    expect([ trip.arrived_at, trip.started_at, trip.completed_at ]).to all(be_present)
  end

  it "only lets the driver say they've arrived near the pickup" do
    move(driver, lat: 40.1900, lon: 44.5300)
    expect { TripLifecycle.arrive!(trip, driver.reload) }.to raise_error(TripLifecycle::Error, "too_far")
  end

  it "keeps the steps in order and to the assigned driver" do
    expect { TripLifecycle.start!(trip, driver) }.to raise_error(TripLifecycle::Error, "not_allowed")
    expect { TripLifecycle.arrive!(trip, online_driver) }.to raise_error(TripLifecycle::Error, "not_allowed")
  end

  describe "cancelling" do
    it "is free for the rider at first, then costs the tariff's fee" do
      TripLifecycle.cancel!(trip, by: trip.rider)
      expect(trip.reload).to have_attributes(status: "cancelled", cancelled_by: "rider", cancellation_fee: 0)

      late = book.tap { |other| Dispatch.accept!(other.offers.sole) }.reload
      travel 3.minutes do
        TripLifecycle.cancel!(late, by: late.rider)
      end
      expect(late.reload.cancellation_fee).to eq(300)
    end

    it "is free while still searching, and stops the offers" do
      searching = book
      TripLifecycle.cancel!(searching, by: searching.rider)
      expect(searching.reload.cancellation_fee).to eq(0)
      expect(searching.offers.pending).to be_empty
    end

    it "isn't possible once the trip has started, or for someone else" do
      TripLifecycle.arrive!(trip, driver)
      expect { TripLifecycle.cancel!(trip, by: create(:user)) }.to raise_error(TripLifecycle::Error)
      TripLifecycle.start!(trip, driver)
      expect { TripLifecycle.cancel!(trip, by: trip.rider) }.to raise_error(TripLifecycle::Error)
    end

    it "puts a trip the driver hands back up for another driver" do
      other = online_driver(lat: 40.1800, lon: 44.5140)
      TripLifecycle.cancel!(trip, by: driver)
      expect(trip.reload).to have_attributes(status: "searching", driver_profile: nil)
      expect(trip.offers.pending.sole.driver_profile).to eq(other)
    end
  end
end
