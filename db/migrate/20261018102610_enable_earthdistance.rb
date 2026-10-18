class EnableEarthdistance < ActiveRecord::Migration[8.1]
  def change
    enable_extension "cube"
    enable_extension "earthdistance"
  end
end
