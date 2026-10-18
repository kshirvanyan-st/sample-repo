require "rails_helper"

RSpec.describe DailyMetric, type: :model do
  it "computes a day's numbers from the source tables" do
    buyer = create(:user, :onboarded)
    pack = create(:coin_pack, coins: 500, bonus_coins: 50, price_cents: 499)
    Purchase.start!(buyer, pack).fulfill!
    Ahoy::Visit.create!(visit_token: "v1", visitor_token: "t1", user: buyer, started_at: Time.current)
    stream = create(:stream, :live, started_at: Time.current, viewer_seconds: 7200)
    GiftTransaction.send!(sender: buyer, stream: stream, gift: create(:gift, coins: 50))

    DailyMetric.compute!(Date.current)

    row = DailyMetric.find_by!(date: Date.current)
    expect(row).to have_attributes(payers: 1, purchases: 1, revenue_cents: 499, coins_purchased: 550, coins_spent: 50,
      gift_coins: 50, active_users: 1, streams: 1, viewer_seconds: 7200)
    expect(row.signups).to be >= 2
  end

  it "is idempotent" do
    2.times { DailyMetric.compute!(Date.current) }
    expect(DailyMetric.where(date: Date.current).count).to eq(1)
  end

  it "ignores purchases that were never paid" do
    Purchase.start!(create(:user), create(:coin_pack))
    DailyMetric.compute!(Date.current)
    expect(DailyMetric.find_by!(date: Date.current).revenue_cents).to eq(0)
  end
end
