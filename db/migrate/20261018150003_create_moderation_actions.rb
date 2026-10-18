class CreateModerationActions < ActiveRecord::Migration[8.1]
  def change
    # Audit log: every action a moderator or admin takes.
    create_table :moderation_actions do |t|
      t.references :moderator, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.references :target, polymorphic: true, null: false
      t.string :note
      t.datetime :created_at, null: false
    end

    add_index :moderation_actions, :created_at
  end
end
