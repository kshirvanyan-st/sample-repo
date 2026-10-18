require "rails_helper"

RSpec.describe DriverWallet do
  let(:driver) { create(:driver_profile, :approved) }
  let(:wallet) { DriverWallet.new(driver) }

  it "keeps the balance and an entry for every change" do
    wallet.credit!(5000, kind: :top_up)
    wallet.debit!(120, kind: :adjustment, note: "test")
    expect(driver.reload.balance).to eq(4880)
    expect(driver.ledger_entries.order(:id).pluck(:amount, :balance_after)).to eq([ [ 5000, 5000 ], [ -120, 4880 ] ])
  end

  it "lets the balance go negative (drivers owe commission on cash rides)" do
    wallet.debit!(300, kind: :adjustment, note: "test")
    expect(driver.reload.balance).to eq(-300)
  end

  it "refuses zero or negative amounts" do
    expect { wallet.credit!(0, kind: :top_up) }.to raise_error(ArgumentError)
    expect { wallet.debit!(-5, kind: :adjustment) }.to raise_error(ArgumentError)
  end

  it "never changes or deletes ledger entries" do
    entry = wallet.credit!(1000, kind: :top_up)
    expect { entry.update!(amount: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { entry.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
