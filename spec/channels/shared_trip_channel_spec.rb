require "rails_helper"

RSpec.describe SharedTripChannel, type: :channel do
  let!(:driver) { online_driver }
  let(:trip) { book.tap { |trip| Dispatch.accept!(trip.offers.sole) }.reload }

  it "lets anyone with an active link listen, without signing in" do
    stub_connection current_user: nil
    subscribe token: ShareLink.for(trip).token
    expect(subscription).to have_stream_from(TripChannel.broadcasting_for(trip))
    expect(transmissions.last).to include("type" => "sync", "status" => "accepted", "lat" => trip.driver_profile.location.location.y)
  end

  it "turns away a wrong or expired link" do
    stub_connection current_user: nil
    subscribe token: "wrong"
    expect(subscription).to be_rejected

    link = ShareLink.for(trip)
    TripLifecycle.cancel!(trip, by: trip.rider)
    travel ShareLink::AFTER_END + 1.minute do
      subscribe token: link.token
      expect(subscription).to be_rejected
    end
  end
end
