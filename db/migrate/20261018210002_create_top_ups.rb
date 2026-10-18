class CreateTopUps < ActiveRecord::Migration[8.1]
  def change
    create_table :top_ups do |t|
      t.references :driver_profile, null: false, foreign_key: true
      t.integer :amount, null: false
      t.integer :status, null: false, default: 0 # pending, paid, failed, expired
      t.string :provider, null: false
      t.string :provider_payment_id
      t.datetime :paid_at
      t.timestamps
    end
    add_check_constraint :top_ups, "amount BETWEEN 1000 AND 50000", name: "top_ups_amount_range"

    # Every provider callback we have processed, so a redelivered one is ignored.
    create_table :payment_events do |t|
      t.string :provider, null: false
      t.string :event_id, null: false
      t.string :event_type
      t.datetime :created_at, null: false
    end
    add_index :payment_events, %i[ provider event_id ], unique: true

    # One SMS statement per driver per day.
    create_table :daily_statements do |t|
      t.references :driver_profile, null: false, foreign_key: true, index: false
      t.date :day, null: false
      t.jsonb :totals, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :daily_statements, %i[ driver_profile_id day ], unique: true
  end
end
