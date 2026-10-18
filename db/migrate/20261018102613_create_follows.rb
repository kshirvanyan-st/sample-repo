class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }, index: false
      t.references :followee, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :follows, %i[follower_id followee_id], unique: true
    add_check_constraint :follows, "follower_id <> followee_id", name: "follows_not_self"
  end
end
