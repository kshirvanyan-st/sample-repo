class AddIngestProtocolToStreams < ActiveRecord::Migration[8.1]
  def change
    # How the broadcaster sends video ("webrtc" or "rtmp"); decides how viewers play it.
    add_column :streams, :ingest_protocol, :string
  end
end
