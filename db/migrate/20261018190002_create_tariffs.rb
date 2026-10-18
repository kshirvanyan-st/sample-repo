class CreateTariffs < ActiveRecord::Migration[8.1]
  def change
    # One tariff per vehicle class. Amounts are whole drams (AMD).
    create_table :tariffs do |t|
      t.integer :vehicle_class, null: false, index: { unique: true }
      t.integer :base_fare, null: false
      t.integer :per_km, null: false
      t.integer :per_minute, null: false
      t.integer :minimum_fare, null: false
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_check_constraint :tariffs, "base_fare >= 0 AND per_km >= 0 AND per_minute >= 0 AND minimum_fare >= 0", name: "tariffs_amounts_not_negative"
  end
end
