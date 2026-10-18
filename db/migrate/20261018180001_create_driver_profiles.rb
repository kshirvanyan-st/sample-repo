class CreateDriverProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :status, null: false, default: 0
      t.string :license_number
      t.date :license_expires_on
      t.text :review_note
      t.datetime :submitted_at
      t.datetime :approved_at
      t.timestamps
    end
    add_index :driver_profiles, %i[ status submitted_at ]
    add_check_constraint :driver_profiles, "status BETWEEN 0 AND 5", name: "driver_profiles_status_known"
  end
end
