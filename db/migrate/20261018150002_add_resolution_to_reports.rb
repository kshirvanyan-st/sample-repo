class AddResolutionToReports < ActiveRecord::Migration[8.1]
  def change
    add_reference :reports, :resolved_by, foreign_key: { to_table: :users }
    add_column :reports, :resolved_at, :datetime
    add_column :reports, :resolution, :integer
  end
end
