class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :messages, %i[conversation_id created_at]
    # Unread counts: messages in a conversation that haven't been read yet.
    add_index :messages, %i[conversation_id sender_id], where: "read_at IS NULL", name: "index_messages_unread"
  end
end
