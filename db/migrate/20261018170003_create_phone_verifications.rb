class CreatePhoneVerifications < ActiveRecord::Migration[8.1]
  def change
    create_table :phone_verifications do |t|
      t.string :phone, null: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :consumed_at
      t.string :ip_address
      t.timestamps
    end
    add_index :phone_verifications, %i[ phone created_at ]
  end
end
