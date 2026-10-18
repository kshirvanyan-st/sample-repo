class CreateStreamComments < ActiveRecord::Migration[8.1]
  def change
    create_table :stream_comments do |t|
      t.references :stream, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :body, null: false

      t.timestamps
    end

    add_index :stream_comments, %i[stream_id created_at]
  end
end
