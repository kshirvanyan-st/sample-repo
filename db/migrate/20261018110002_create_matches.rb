class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :user_a, null: false, foreign_key: { to_table: :users }, index: false
      t.references :user_b, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :matches, %i[user_a_id user_b_id], unique: true
    add_check_constraint :matches, "user_a_id < user_b_id", name: "matches_ordered_pair"
  end
end
