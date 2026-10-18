require "rails_helper"

RSpec.describe Purchase, type: :model do
  let(:user) { create(:user) }
  let(:pack) { create(:coin_pack, coins: 500, bonus_coins: 50, price_cents: 499) }

  it "copies the price and coins from the pack when it starts" do
    purchase = Purchase.start!(user, pack)
    expect(purchase).to have_attributes(coins: 550, amount_cents: 499, currency: "usd", status: "pending")
  end

  it "credits the coins exactly once" do
    purchase = Purchase.start!(user, pack)
    expect(purchase.fulfill!(payment_intent_id: "pi_1")).to be(true)
    expect(purchase.fulfill!).to be(false)
    expect(user.reload.coin_balance).to eq(550)
    expect(purchase.reload).to have_attributes(status: "paid", stripe_payment_intent_id: "pi_1", paid_at: be_present)
  end

  it "takes back unspent coins on refund, never more than the balance" do
    purchase = Purchase.start!(user, pack)
    purchase.fulfill!
    Wallet.new(user).debit!(500, kind: :gift_sent)

    expect(purchase.refund!).to be(true)
    expect(user.reload.coin_balance).to eq(0)
    expect(purchase.reload).to be_refunded
    expect(purchase.refund!).to be(false)
  end

  it "doesn't refund purchases that were never paid" do
    expect(Purchase.start!(user, pack).refund!).to be(false)
  end
end
