class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :liker, null: false, foreign_key: { to_table: :users }, index: false
      t.references :likee, null: false, foreign_key: { to_table: :users }, index: false
      t.integer :kind, null: false, default: 0

      t.timestamps
    end

    add_index :likes, %i[liker_id likee_id], unique: true
    add_index :likes, %i[likee_id kind]
    add_check_constraint :likes, "liker_id <> likee_id", name: "likes_not_self"
  end
end
