class CreateDailyMetrics < ActiveRecord::Migration[8.1]
  def change
    # One row per day, recomputed hourly by DailyMetricsJob; the revenue dashboard reads these.
    create_table :daily_metrics do |t|
      t.date :date, null: false, index: { unique: true }
      t.integer :signups, null: false, default: 0
      t.integer :active_users, null: false, default: 0
      t.integer :payers, null: false, default: 0
      t.integer :purchases, null: false, default: 0
      t.integer :revenue_cents, null: false, default: 0
      t.integer :refunds_cents, null: false, default: 0
      t.integer :coins_purchased, null: false, default: 0
      t.integer :coins_spent, null: false, default: 0
      t.integer :gift_coins, null: false, default: 0
      t.integer :matches, null: false, default: 0
      t.integer :messages, null: false, default: 0
      t.integer :streams, null: false, default: 0
      t.integer :viewer_seconds, null: false, default: 0

      t.timestamps
    end

    # Watch time, accumulated as viewers leave (StreamPresenceChannel).
    add_column :streams, :viewer_seconds, :integer, null: false, default: 0
  end
end
