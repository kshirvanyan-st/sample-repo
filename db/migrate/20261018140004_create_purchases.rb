class CreatePurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :coin_pack, null: false, foreign_key: true
      t.integer :coins, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false
      t.integer :status, null: false, default: 0
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.datetime :paid_at
      t.datetime :refunded_at

      t.timestamps
    end

    add_index :purchases, :stripe_checkout_session_id, unique: true
    add_index :purchases, :stripe_payment_intent_id
  end
end
