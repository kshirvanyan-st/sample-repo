class CreateStreamViewers < ActiveRecord::Migration[8.1]
  def change
    # One row per open watch page (Action Cable subscription); a person with two tabs counts once.
    create_table :stream_viewers do |t|
      t.references :stream, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :connection_token, null: false

      t.timestamps
    end

    add_index :stream_viewers, :connection_token, unique: true
  end
end
