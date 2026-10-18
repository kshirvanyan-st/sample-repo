class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :trip, null: false, foreign_key: true, index: false
      t.references :rater, null: false, foreign_key: { to_table: :users }
      t.references :ratee, null: false, foreign_key: { to_table: :users }
      t.integer :role, null: false # 0 rider rates driver, 1 driver rates rider
      t.integer :stars, null: false
      t.string :reasons, array: true, null: false, default: []
      t.string :comment
      t.datetime :created_at, null: false
    end
    add_index :ratings, %i[ trip_id role ], unique: true
    add_index :ratings, %i[ ratee_id role created_at ]
    add_check_constraint :ratings, "stars BETWEEN 1 AND 5", name: "ratings_stars_range"

    # Averages over the last Ratings::WINDOW ratings, recomputed after each new one.
    add_column :driver_profiles, :rating_avg, :decimal, precision: 3, scale: 2
    add_column :driver_profiles, :rating_count, :integer, null: false, default: 0
    add_column :driver_profiles, :review_flagged_at, :datetime
    add_column :users, :rider_rating_avg, :decimal, precision: 3, scale: 2
    add_column :users, :rider_rating_count, :integer, null: false, default: 0
  end
end
