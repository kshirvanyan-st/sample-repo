class CreateStripeEvents < ActiveRecord::Migration[8.1]
  def change
    # Every webhook event we've handled, so redelivered events are processed only once.
    create_table :stripe_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.datetime :created_at, null: false
    end

    add_index :stripe_events, :stripe_event_id, unique: true
  end
end
