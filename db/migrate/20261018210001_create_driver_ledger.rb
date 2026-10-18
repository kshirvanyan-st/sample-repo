class CreateDriverLedger < ActiveRecord::Migration[8.1]
  # ledger_entries.kind: 0 commission, 1 top_up, 2 cancellation_payout, 3 adjustment, 4 refund, 5 fee_collection
  ONCE_PER_REFERENCE = "kind IN (0, 1, 2, 5)"

  def change
    # Cached balance in drams; DriverWallet is the only writer (each change also writes a ledger entry).
    add_column :driver_profiles, :balance, :integer, null: false, default: 0

    # Append-only history of every change to a driver's balance.
    create_table :ledger_entries do |t|
      t.references :driver_profile, null: false, foreign_key: true, index: false
      t.integer :kind, null: false
      t.integer :amount, null: false # signed: credits positive, debits negative
      t.integer :balance_after, null: false
      t.references :reference, polymorphic: true, index: false
      t.references :created_by, foreign_key: { to_table: :users } # an admin, for manual entries
      t.string :note
      t.datetime :created_at, null: false
    end
    add_index :ledger_entries, %i[ driver_profile_id created_at ]
    add_index :ledger_entries, %i[ kind created_at ]
    # A trip's commission or payout, or a top-up, can only ever be booked once.
    add_index :ledger_entries, %i[ kind reference_type reference_id ], unique: true, where: ONCE_PER_REFERENCE,
      name: "index_ledger_entries_once_per_reference"
    add_check_constraint :ledger_entries, "amount <> 0", name: "ledger_entries_amount_not_zero"

    # One row: platform-wide money settings, edited in Admin → Settings.
    create_table :business_settings do |t|
      t.integer :commission_percent, null: false, default: 10
      t.integer :min_balance, null: false, default: -2000
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_check_constraint :business_settings, "commission_percent BETWEEN 0 AND 50", name: "business_settings_commission_range"

    add_column :trips, :commission, :integer
    add_column :trips, :outstanding_fee, :integer, null: false, default: 0 # earlier cancellation fees added to this fare
    add_column :users, :outstanding_fee, :integer, null: false, default: 0 # cancellation fees owed by a rider
  end
end
