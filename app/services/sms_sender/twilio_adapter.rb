module SmsSender
  # Needs TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN, plus TWILIO_MESSAGING_SERVICE_SID (preferred)
  # or TWILIO_FROM (a sender number or alphanumeric sender ID).
  class TwilioAdapter
    TIMEOUT = 10 # seconds

    def deliver(to:, body:)
      client.messages.create(to: to, body: body, **sender)
    rescue ::Twilio::REST::TwilioError => e
      raise DeliveryError, e.message
    end

    private
      def sender
        if (service = ENV["TWILIO_MESSAGING_SERVICE_SID"].presence)
          { messaging_service_sid: service }
        else
          { from: ENV.fetch("TWILIO_FROM") }
        end
      end

      def client
        ::Twilio::REST::Client.new(ENV.fetch("TWILIO_ACCOUNT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN")).tap do |client|
          client.http_client = ::Twilio::HTTP::Client.new(timeout: TIMEOUT)
        end
      end
  end
end
