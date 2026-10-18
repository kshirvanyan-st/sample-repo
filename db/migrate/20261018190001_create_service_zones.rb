class CreateServiceZones < ActiveRecord::Migration[8.1]
  def change
    create_table :service_zones do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.multi_polygon :area, geographic: true, srid: 4326, null: false
      t.timestamps
    end
    add_index :service_zones, :area, using: :gist
  end
end
