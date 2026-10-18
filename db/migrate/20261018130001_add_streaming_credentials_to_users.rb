class AddStreamingCredentialsToUsers < ActiveRecord::Migration[8.1]
  def change
    # Generated on first use (User#streaming_credentials!), so existing users need no backfill.
    add_column :users, :stream_path, :string
    add_column :users, :stream_key, :string
    add_index :users, :stream_path, unique: true
  end
end
