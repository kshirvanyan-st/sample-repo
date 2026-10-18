class CreateCoinPacks < ActiveRecord::Migration[8.1]
  def change
    create_table :coin_packs do |t|
      t.string :name, null: false
      t.integer :coins, null: false
      t.integer :bonus_coins, null: false, default: 0
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: "usd"
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
