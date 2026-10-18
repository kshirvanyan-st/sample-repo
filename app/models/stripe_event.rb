class StripeEvent < ApplicationRecord
  # Records the event and returns true, or false when it was already handled (a redelivery).
  # ON CONFLICT DO NOTHING instead of rescuing the unique violation, which would abort the
  # surrounding transaction in Postgres.
  def self.record_once(event)
    insert({ stripe_event_id: event.id, event_type: event.type, created_at: Time.current },
      unique_by: :stripe_event_id, returning: :id).rows.any?
  end
end
