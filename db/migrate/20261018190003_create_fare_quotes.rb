class CreateFareQuotes < ActiveRecord::Migration[8.1]
  def change
    # A price shown to a rider for a route. Phase 4 books a ride from a quote, at the quoted price.
    create_table :fare_quotes do |t|
      t.references :user, null: false, foreign_key: true
      t.st_point :pickup, geographic: true, srid: 4326, null: false
      t.string :pickup_address
      t.st_point :dropoff, geographic: true, srid: 4326, null: false
      t.string :dropoff_address
      t.integer :distance_m, null: false
      t.integer :duration_s, null: false
      t.boolean :approximate, null: false, default: false
      t.jsonb :route, null: false, default: {}
      t.jsonb :prices, null: false, default: {}
      t.jsonb :tariffs, null: false, default: {}
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
