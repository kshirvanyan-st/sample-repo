# The only way a driver's balance changes. Each change locks the driver's row, writes a ledger
# entry with the resulting balance and updates the cached balance, all in one transaction, so
# concurrent commissions and top-ups can't lose or double-count money.
#
# The balance may go negative: drivers collect cash and owe the commission. Below
# BusinessSetting#min_balance they can't go online until they top up.
class DriverWallet
  def initialize(driver_profile)
    @driver = driver_profile
  end

  def credit!(amount, kind:, reference: nil, created_by: nil, note: nil)
    raise ArgumentError, "amount must be positive" unless amount.to_i.positive?

    move!(amount, kind:, reference:, created_by:, note:)
  end

  def debit!(amount, kind:, reference: nil, created_by: nil, note: nil)
    raise ArgumentError, "amount must be positive" unless amount.to_i.positive?

    move!(-amount, kind:, reference:, created_by:, note:)
  end

  private
    def move!(amount, kind:, reference:, created_by:, note:)
      @driver.with_lock do
        balance = @driver.balance + amount
        @driver.update_column(:balance, balance)
        @driver.ledger_entries.create!(kind: kind, amount: amount, balance_after: balance, reference: reference,
          created_by: created_by, note: note)
      end
    end
end
