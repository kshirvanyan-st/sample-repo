# Browsers pause GPS when the driver app is in the background, so a driver whose position hasn't
# arrived for DriverLocation::FRESH is set offline. Drivers on a trip stay online.
class StaleDriversJob < ApplicationJob
  queue_as :default

  def perform
    stale = DriverProfile.online
      .where.not(id: DriverLocation.fresh.select(:driver_profile_id))
      .where.not(id: Trip.busy.select(:driver_profile_id))
      .where(online_at: ...DriverLocation::FRESH.ago) # just went online: give the first fix time to arrive
    stale.find_each do |driver|
      driver.go_offline!
      Notify.driver(driver)
    end
  end
end
