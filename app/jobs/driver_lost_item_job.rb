# Tells the driver a rider reported something left in the car. Phone numbers aren't shared: support
# connects them.
class DriverLostItemJob < ApplicationJob
  queue_as :default

  def perform(ticket)
    driver = ticket.trip.driver
    SupportSmsJob.perform_now(driver, "safety.sms.lost_item_driver", id: ticket.trip_id)
    Notify.driver(ticket.trip.driver_profile)
  end
end
