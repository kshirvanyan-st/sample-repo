class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    # Columns are nullable so a driver can save a half-finished application; DriverProfile#submit! checks them.
    create_table :vehicles do |t|
      t.references :driver_profile, null: false, foreign_key: true, index: { unique: true }
      t.string :make
      t.string :model
      t.string :color
      t.integer :year
      t.string :plate_number, index: { unique: true }
      t.integer :vehicle_class, null: false, default: 0
      t.date :registration_expires_on
      t.date :insurance_expires_on
      t.timestamps
    end
  end
end
