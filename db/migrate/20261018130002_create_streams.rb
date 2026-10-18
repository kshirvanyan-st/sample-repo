class CreateStreams < ActiveRecord::Migration[8.1]
  def change
    create_table :streams do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :title, null: false
      t.integer :category, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :viewers_count, null: false, default: 0
      t.integer :peak_viewers, null: false, default: 0

      t.timestamps
    end

    add_index :streams, %i[user_id created_at]
    add_index :streams, :status, where: "status = 1", name: "index_streams_live"
    # A broadcaster has at most one stream that isn't over yet.
    add_index :streams, :user_id, unique: true, where: "status IN (0, 1)", name: "index_streams_one_open_per_user"
  end
end
