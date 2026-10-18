# The rider's receipt by SMS: fare (paid in cash) and route.
class TripReceiptJob < ApplicationJob
  queue_as :default
  retry_on SmsSender::DeliveryError, wait: :polynomially_longer, attempts: 5

  def perform(trip)
    rider = trip.rider
    I18n.with_locale(rider.locale || I18n.default_locale) do
      body = I18n.t("payments.sms.receipt", fare: ApplicationController.helpers.amd(trip.fare),
        from: trip.pickup_address.to_s.truncate(40), to: trip.dropoff_address.to_s.truncate(40))
      SmsSender.deliver(to: rider.phone, body: body)
    end
  end
end
