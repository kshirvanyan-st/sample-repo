class CreateSafety < ActiveRecord::Migration[8.1]
  def change
    # Read-only live view of a trip for whoever has the link (the rider's family). It works while the
    # trip is open and for ShareLink::AFTER_END once it ends.
    create_table :share_links do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :token, null: false, index: { unique: true }
      t.datetime :created_at, null: false
    end

    create_table :emergency_contacts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone, null: false
      t.timestamps
    end
  end
end
