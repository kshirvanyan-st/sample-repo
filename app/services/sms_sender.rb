# Sends text messages through the adapter set in config.x.sms.adapter:
# :twilio (production), :log (development) or :test (keeps messages in memory for specs).
module SmsSender
  class DeliveryError < StandardError; end

  ADAPTERS = { twilio: "SmsSender::TwilioAdapter", log: "SmsSender::LogAdapter", test: "SmsSender::TestAdapter" }.freeze

  def self.deliver(to:, body:)
    adapter.deliver(to: to, body: body)
  end

  def self.adapter
    ADAPTERS.fetch(Rails.configuration.x.sms.adapter.to_sym).constantize.new
  end
end
