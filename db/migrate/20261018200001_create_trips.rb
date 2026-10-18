class CreateTrips < ActiveRecord::Migration[8.1]
  # status: 0 searching, 1 accepted (driver on the way), 2 arrived, 3 in_progress, 4 completed, 5 cancelled, 6 no_drivers
  DRIVER_BUSY = "status IN (1, 2, 3)"
  RIDER_OPEN = "status IN (0, 1, 2, 3)"

  def change
    create_table :trips do |t|
      t.references :rider, null: false, foreign_key: { to_table: :users }
      t.references :driver_profile, foreign_key: true, index: false
      t.references :fare_quote, null: false, foreign_key: true
      t.integer :vehicle_class, null: false
      t.integer :status, null: false, default: 0
      t.st_point :pickup, geographic: true, srid: 4326, null: false
      t.string :pickup_address
      t.st_point :dropoff, geographic: true, srid: 4326, null: false
      t.string :dropoff_address
      t.integer :fare, null: false
      t.integer :cancellation_fee, null: false, default: 0
      t.string :cancelled_by
      t.string :cancel_reason
      t.datetime :accepted_at
      t.datetime :arrived_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.timestamps
    end
    add_check_constraint :trips, "status BETWEEN 0 AND 6", name: "trips_status_known"
    add_check_constraint :trips, "fare >= 0 AND cancellation_fee >= 0", name: "trips_money_not_negative"
    # The database itself refuses a second active trip for a driver, or a second open trip for a rider.
    add_index :trips, :driver_profile_id, unique: true, where: DRIVER_BUSY, name: "index_trips_one_active_per_driver"
    add_index :trips, :rider_id, unique: true, where: RIDER_OPEN, name: "index_trips_one_open_per_rider"
    add_index :trips, %i[ driver_profile_id created_at ]
    add_index :trips, :status
  end
end
