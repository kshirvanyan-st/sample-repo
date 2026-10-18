class CreateGifts < ActiveRecord::Migration[8.1]
  def change
    create_table :gifts do |t|
      t.string :name, null: false
      t.string :emoji, null: false
      t.integer :coins, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    create_table :gift_transactions do |t|
      t.references :gift, null: false, foreign_key: true
      t.references :stream, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.integer :coins, null: false
      t.datetime :created_at, null: false
    end

    add_index :gift_transactions, %i[stream_id sender_id]
    add_check_constraint :gift_transactions, "coins > 0", name: "gift_transactions_coins_positive"
    add_check_constraint :gift_transactions, "sender_id <> recipient_id", name: "gift_transactions_not_self"
  end
end
