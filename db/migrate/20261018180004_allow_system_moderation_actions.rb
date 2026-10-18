class AllowSystemModerationActions < ActiveRecord::Migration[8.1]
  def change
    # No moderator means the system did it (e.g. suspending a driver whose documents expired).
    change_column_null :moderation_actions, :moderator_id, true
  end
end
