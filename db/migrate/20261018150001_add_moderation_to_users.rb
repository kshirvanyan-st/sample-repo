class AddModerationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :banned_at, :datetime
    add_column :users, :ban_reason, :string
    add_column :users, :streaming_suspended_at, :datetime
    add_index :users, :banned_at, where: "banned_at IS NOT NULL"
  end
end
