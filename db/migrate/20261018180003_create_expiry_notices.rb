class CreateExpiryNotices < ActiveRecord::Migration[8.1]
  def change
    # One row per reminder sent, so DocumentExpiryJob never texts a driver twice for the same thing.
    create_table :expiry_notices do |t|
      t.references :driver_profile, null: false, foreign_key: true, index: false
      t.string :document, null: false
      t.date :expires_on, null: false
      t.string :stage, null: false
      t.datetime :created_at, null: false
    end
    add_index :expiry_notices, %i[ driver_profile_id document expires_on stage ], unique: true, name: "index_expiry_notices_once"
  end
end
