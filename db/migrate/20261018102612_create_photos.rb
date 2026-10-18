class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :profile, null: false, foreign_key: true, index: false
      t.integer :position, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :photos, %i[profile_id position]
  end
end
