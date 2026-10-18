# Online payments for driver top-ups, behind an adapter (config.x.payments.adapter).
# Only the provider's signed callback credits money (Payments.process_callback); a real provider
# (Ameriabank vPOS / ArCa, Idram, Telcell) is one more adapter with checkout_url and verify!.
module Payments
  class Error < StandardError; end

  # A verified callback from a provider. type: "paid" or "failed".
  Event = Data.define(:id, :type, :top_up_id, :payment_id, :amount)

  ADAPTERS = { sandbox: "Payments::SandboxAdapter" }.freeze

  def self.enabled?
    Rails.configuration.x.payments.adapter.present?
  end

  def self.adapter(name = Rails.configuration.x.payments.adapter)
    raise Error, "online payments are not configured" if name.blank?

    ADAPTERS.fetch(name.to_sym) { raise Error, "unknown payment provider #{name}" }.constantize.new
  end

  # Verifies, de-duplicates and applies a provider callback. Returns the top-up, or nil for a repeat.
  def self.process_callback(provider, raw_body, headers)
    adapter = adapter(provider)
    event = adapter.verify!(raw_body, headers)
    return unless PaymentEvent.record_once(provider: adapter.name, event_id: event.id, event_type: event.type)

    top_up = TopUp.find_by!(id: event.top_up_id, provider: adapter.name)
    event.type == "paid" ? top_up.fulfill!(payment_id: event.payment_id, amount: event.amount) : top_up.fail!
    top_up
  end
end
