class AddDiscoveryPreferencesToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :age_min, :integer, null: false, default: 18
    add_column :profiles, :age_max, :integer, null: false, default: 99
    add_column :profiles, :max_distance_km, :integer, default: 50
  end
end
