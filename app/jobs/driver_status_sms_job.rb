# Tells a driver by SMS that their application was approved, sent back, rejected or suspended.
class DriverStatusSmsJob < ApplicationJob
  queue_as :default
  retry_on SmsSender::DeliveryError, wait: :polynomially_longer, attempts: 5

  def perform(profile)
    return unless profile.status.in?(%w[ approved needs_changes rejected suspended ])

    I18n.with_locale(profile.user.locale || I18n.default_locale) do
      SmsSender.deliver(to: profile.user.phone, body: I18n.t("drivers.sms.#{profile.status}"))
    end
  end
end
