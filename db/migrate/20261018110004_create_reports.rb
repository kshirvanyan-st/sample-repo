class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reported, null: false, foreign_key: { to_table: :users }
      t.integer :reason, null: false, default: 0
      t.text :details
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :reports, :status
  end
end
