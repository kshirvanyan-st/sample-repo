class CreateSavedPlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_places do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :kind, null: false, default: 2
      t.string :label
      t.string :address, null: false
      t.st_point :location, geographic: true, srid: 4326
      t.timestamps
    end
    # One home and one work place per user; any number of "other" places.
    add_index :saved_places, %i[ user_id kind ], unique: true, where: "kind IN (0, 1)", name: "index_saved_places_one_home_one_work"
    add_index :saved_places, :location, using: :gist
  end
end
