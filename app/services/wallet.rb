# The only way coins and earnings move. Each change locks the user's row, writes a
# ledger entry with the resulting balance, and updates the cached balance, all in one
# transaction, so concurrent purchases and gifts can't lose or double-spend coins.
class Wallet
  class InsufficientFunds < StandardError; end

  BALANCE_COLUMNS = { coins: :coin_balance, earnings: :earnings_balance }.freeze

  def initialize(user)
    @user = user
  end

  def credit!(amount, account: :coins, kind:, reference: nil)
    raise ArgumentError, "amount must be positive" unless amount.positive?

    move!(amount, account:, kind:, reference:)
  end

  def debit!(amount, account: :coins, kind:, reference: nil)
    raise ArgumentError, "amount must be positive" unless amount.positive?

    move!(-amount, account:, kind:, reference:)
  end

  private
    def move!(amount, account:, kind:, reference:)
      column = BALANCE_COLUMNS.fetch(account)

      entry = @user.with_lock do
        balance = @user.public_send(column) + amount
        raise InsufficientFunds, "Not enough coins" if balance.negative?

        @user.update_column(column, balance)
        @user.ledger_entries.create!(account:, kind:, amount:, balance_after: balance, reference:)
      end

      # Only show the new balance once it's committed (gifts wrap two wallet moves in one transaction).
      ActiveRecord.after_all_transactions_commit { broadcast_balance }
      entry
    end

    def broadcast_balance
      Turbo::StreamsChannel.broadcast_update_to [ @user, :notifications ], targets: ".coin-balance", html: @user.reload.coin_balance.to_s
    end
end
