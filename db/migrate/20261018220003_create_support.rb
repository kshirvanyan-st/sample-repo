class CreateSupport < ActiveRecord::Migration[8.1]
  def change
    # kind: 0 sos, 1 complaint, 2 lost_item, 3 fare, 4 other, 5 safety (from a rating)
    # status: 0 open, 1 in_progress, 2 resolved. priority: 0 normal, 1 urgent
    create_table :support_tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trip, foreign_key: true
      t.integer :kind, null: false
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 0
      t.st_point :location, geographic: true, srid: 4326
      t.references :assignee, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :support_tickets, %i[ status priority created_at ]

    create_table :ticket_messages do |t|
      t.references :support_ticket, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.boolean :internal, null: false, default: false # staff-only note
      t.datetime :created_at, null: false
    end
  end
end
