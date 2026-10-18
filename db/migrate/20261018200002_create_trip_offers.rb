class CreateTripOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :trip_offers do |t|
      t.references :trip, null: false, foreign_key: true, index: false
      t.references :driver_profile, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :eta_s
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :trip_offers, %i[ trip_id driver_profile_id ], unique: true
    add_check_constraint :trip_offers, "status BETWEEN 0 AND 3", name: "trip_offers_status_known"
  end
end
