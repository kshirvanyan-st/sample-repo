class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :phone, null: false, index: { unique: true }
      t.string :name
      t.integer :role, null: false, default: 0
      t.string :locale
      t.datetime :banned_at
      t.timestamps
    end
    add_check_constraint :users, "role IN (0, 1, 2, 3)", name: "users_role_known"
  end
end
