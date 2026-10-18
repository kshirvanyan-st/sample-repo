require "rails_helper"

RSpec.describe TripChannel, type: :channel do
  let!(:driver) { online_driver }
  let(:trip) { book.tap { |trip| Dispatch.accept!(trip.offers.sole) } }

  it "lets the rider and the driver listen" do
    [ trip.rider, driver.user ].each do |user|
      stub_connection current_user: user
      subscribe id: trip.id
      expect(subscription).to have_stream_for(trip)
    end
    expect(transmissions.last).to include("type" => "sync", "status" => "accepted")
  end

  it "turns everyone else away" do
    stub_connection current_user: create(:user)
    subscribe id: trip.id
    expect(subscription).to be_rejected
  end
end
