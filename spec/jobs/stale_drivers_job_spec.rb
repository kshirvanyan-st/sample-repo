require "rails_helper"

RSpec.describe StaleDriversJob, type: :job do
  it "takes drivers offline when their position stops arriving" do
    stale = online_driver(fresh: false)
    fresh = online_driver
    StaleDriversJob.perform_now
    expect(stale.reload).not_to be_online
    expect(fresh.reload).to be_online
  end

  it "gives a driver who just went online time for a first fix, and leaves drivers on a trip alone" do
    just_online = create(:driver_profile, :approved).tap(&:go_online!)
    on_trip = online_driver(fresh: false)
    create(:trip_on_the_way, driver_profile: on_trip)
    StaleDriversJob.perform_now
    expect(just_online.reload).to be_online
    expect(on_trip.reload).to be_online
  end
end
