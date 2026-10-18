require "rails_helper"

RSpec.describe Wallet do
  let(:user) { create(:user) }
  let(:wallet) { described_class.new(user) }

  it "credits and debits with a ledger entry for each move" do
    wallet.credit!(100, kind: :purchase)
    wallet.debit!(30, kind: :gift_sent)

    expect(user.reload.coin_balance).to eq(70)
    expect(user.ledger_entries.order(:id).pluck(:kind, :amount, :balance_after)).to eq([ [ "purchase", 100, 100 ], [ "gift_sent", -30, 70 ] ])
  end

  it "refuses to overdraw and changes nothing" do
    wallet.credit!(10, kind: :purchase)
    expect { wallet.debit!(11, kind: :gift_sent) }.to raise_error(Wallet::InsufficientFunds)
    expect(user.reload.coin_balance).to eq(10)
    expect(user.ledger_entries.count).to eq(1)
  end

  it "keeps earnings separate from spendable coins" do
    wallet.credit!(40, account: :earnings, kind: :gift_received)
    expect(user.reload).to have_attributes(coin_balance: 0, earnings_balance: 40)
    expect { wallet.debit!(1, kind: :gift_sent) }.to raise_error(Wallet::InsufficientFunds)
  end

  it "rejects zero and negative amounts" do
    expect { wallet.credit!(0, kind: :purchase) }.to raise_error(ArgumentError)
    expect { wallet.debit!(-5, kind: :gift_sent) }.to raise_error(ArgumentError)
  end

  it "keeps the ledger append-only" do
    entry = wallet.credit!(5, kind: :adjustment)
    expect { entry.update!(amount: 500) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { entry.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "the database refuses a negative balance even if the wallet is bypassed" do
    expect { user.update_column(:coin_balance, -1) }.to raise_error(ActiveRecord::StatementInvalid, /coin_balance_not_negative/)
  end

  it "broadcasts the new balance to the user's open pages" do
    broadcasts = capture_turbo_stream_broadcasts([ user, :notifications ]) { wallet.credit!(25, kind: :purchase) }
    expect(broadcasts.sole["targets"]).to eq(".coin-balance")
    expect(broadcasts.sole.to_html).to include("25")
  end
end
