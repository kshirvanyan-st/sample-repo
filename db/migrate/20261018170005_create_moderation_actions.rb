class CreateModerationActions < ActiveRecord::Migration[8.1]
  def change
    # Append-only audit log of staff actions (role changes, bans; driver approvals from Phase 2).
    create_table :moderation_actions do |t|
      t.references :moderator, null: false, foreign_key: { to_table: :users }
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.jsonb :details, null: false, default: {}
      t.datetime :created_at, null: false
    end
  end
end
