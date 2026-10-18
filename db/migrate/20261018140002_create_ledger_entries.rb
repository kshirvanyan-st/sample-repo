class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.integer :account, null: false # coins (spendable) or earnings (from gifts)
      t.integer :kind, null: false
      t.integer :amount, null: false # signed: credits positive, debits negative
      t.integer :balance_after, null: false
      t.references :reference, polymorphic: true
      t.datetime :created_at, null: false
    end

    add_index :ledger_entries, %i[user_id account created_at]
    add_check_constraint :ledger_entries, "amount <> 0", name: "ledger_entries_amount_not_zero"
  end
end
