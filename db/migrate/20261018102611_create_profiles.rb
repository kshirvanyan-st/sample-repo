class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :display_name, null: false
      t.date :birthdate, null: false
      t.integer :gender, null: false, default: 0
      t.integer :looking_for, null: false, default: 0
      t.string :city
      t.text :bio
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.datetime :onboarded_at

      t.timestamps
    end

    # Powers the "people nearby" query in Phase 2: earth_box(ll_to_earth(lat, lng), meters) @> ll_to_earth(...)
    add_index :profiles, "ll_to_earth(latitude::float8, longitude::float8)", using: :gist,
      where: "latitude IS NOT NULL AND longitude IS NOT NULL", name: "index_profiles_on_location"
  end
end
