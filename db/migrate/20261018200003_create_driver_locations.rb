class CreateDriverLocations < ActiveRecord::Migration[8.1]
  def change
    # The latest position of each driver, overwritten every few seconds while online.
    create_table :driver_locations do |t|
      t.references :driver_profile, null: false, foreign_key: true, index: { unique: true }
      t.st_point :location, geographic: true, srid: 4326, null: false
      t.float :heading
      t.float :speed
      t.datetime :recorded_at, null: false
    end
    add_index :driver_locations, :location, using: :gist
    add_index :driver_locations, :recorded_at

    # Breadcrumbs of each trip, for disputes and the replay in the operations dashboard.
    create_table :trip_points do |t|
      t.references :trip, null: false, foreign_key: true
      t.st_point :location, geographic: true, srid: 4326, null: false
      t.datetime :recorded_at, null: false
    end

    add_column :driver_profiles, :online_at, :datetime # nil: offline

    add_column :tariffs, :cancellation_fee, :integer, null: false, default: 300
    add_column :tariffs, :free_cancellation_minutes, :integer, null: false, default: 2
  end
end
