module Payments
  # A pretend bank for development and testing: its checkout page (Payments::SandboxController) lets
  # you approve or decline, then sends a callback signed like a real provider's would be.
  # Never enabled in production unless PAYMENTS_ADAPTER=sandbox is set on purpose (e.g. staging).
  class SandboxAdapter
    SIGNATURE_HEADER = "X-Sandbox-Signature"

    def name
      "sandbox"
    end

    def checkout_path(top_up)
      Rails.application.routes.url_helpers.payments_sandbox_path(top_up)
    end

    def sign(raw_body)
      OpenSSL::HMAC.hexdigest("SHA256", secret, raw_body)
    end

    def verify!(raw_body, headers)
      signature = headers[SIGNATURE_HEADER].to_s
      raise Error, "bad signature" unless ActiveSupport::SecurityUtils.secure_compare(signature, sign(raw_body))

      data = JSON.parse(raw_body)
      Event.new(id: data.fetch("event_id"), type: data.fetch("status"), top_up_id: data.fetch("order_id"),
        payment_id: data["payment_id"], amount: data.fetch("amount"))
    rescue JSON::ParserError, KeyError
      raise Error, "malformed callback"
    end

    private
      def secret
        ENV["PAYMENTS_SANDBOX_SECRET"].presence || Rails.application.key_generator.generate_key("payments sandbox", 32)
      end
  end
end
