class PaymentEvent < ApplicationRecord
  # True only the first time a provider event is seen. INSERT … ON CONFLICT DO NOTHING instead of
  # rescuing the unique violation, which would abort the surrounding transaction.
  def self.record_once(provider:, event_id:, event_type: nil)
    insert({ provider: provider, event_id: event_id, event_type: event_type, created_at: Time.current },
      unique_by: %i[ provider event_id ], returning: :id).any?
  end
end
