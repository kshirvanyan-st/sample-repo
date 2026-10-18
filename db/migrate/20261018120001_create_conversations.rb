class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :match, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.datetime :last_message_at

      t.timestamps
    end
  end
end
