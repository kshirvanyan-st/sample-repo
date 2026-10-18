class AddBalancesToUsers < ActiveRecord::Migration[8.1]
  def change
    # Cached balances; the source of truth is the append-only ledger_entries table.
    add_column :users, :coin_balance, :integer, null: false, default: 0
    add_column :users, :earnings_balance, :integer, null: false, default: 0
    add_check_constraint :users, "coin_balance >= 0", name: "users_coin_balance_not_negative"
    add_check_constraint :users, "earnings_balance >= 0", name: "users_earnings_balance_not_negative"
  end
end
