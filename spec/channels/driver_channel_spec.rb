require "rails_helper"

RSpec.describe DriverChannel, type: :channel do
  let!(:driver) { online_driver }

  it "is only for approved drivers" do
    stub_connection current_user: create(:user)
    subscribe
    expect(subscription).to be_rejected

    stub_connection current_user: create(:driver_profile, :submitted).user
    subscribe
    expect(subscription).to be_rejected
  end

  it "records the driver's position, at most once a second" do
    stub_connection current_user: driver.user
    subscribe
    expect(subscription).to have_stream_for(driver)

    perform :location, lat: 40.1801, lon: 44.5131, heading: 90
    perform :location, lat: 40.1900, lon: 44.5300
    expect(driver.location.reload.location.y).to be_within(0.00001).of(40.1801)
    expect(driver.location.heading).to eq(90)
  end

  it "ignores nonsense coordinates" do
    stub_connection current_user: driver.user
    subscribe
    perform :location, lat: "north", lon: 44.5
    expect(driver.location.reload.location.y).to be_within(0.001).of(40.1790)
  end

  it "leaves breadcrumbs and tells the rider while on a trip" do
    trip = book.tap { |trip| Dispatch.accept!(trip.offers.sole) }
    stub_connection current_user: driver.user
    subscribe
    expect { perform :location, lat: 40.1785, lon: 44.5129 }
      .to have_broadcasted_to(trip).from_channel(TripChannel).with(hash_including(type: "location", lat: 40.1785))
    expect(trip.points.count).to eq(1)
  end
end
