require "rails_helper"

RSpec.describe Analytics::Revenue do
  def paid_purchase(user, cents: 999, coins: 1400, at: Time.current)
    purchase = Purchase.start!(user, create(:coin_pack, price_cents: cents, coins: coins, bonus_coins: 0))
    purchase.fulfill!
    purchase.update_columns(paid_at: at)
    purchase
  end

  def visit(user, at: Time.current)
    Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid, user: user, started_at: at)
  end

  it "computes totals, ARPU, ARPPU and payer conversion" do
    payer, browser = create_list(:user, 2)
    [ payer, browser ].each { |u| visit(u) }
    paid_purchase(payer, cents: 1000)

    totals = described_class.new(days: 30).totals
    expect(totals).to include(revenue_cents: 1000, payers: 1, active_users: 2, payer_conversion: 0.5, arpu_cents: 500.0, arppu_cents: 1000.0)
  end

  it "takes Stripe fees, creator payouts and servers out of gross margin" do
    buyer = create(:user, :onboarded)
    paid_purchase(buyer, cents: 1000, coins: 1000)                     # 1 cent per coin
    GiftTransaction.send!(sender: buyer, stream: create(:stream, :live), gift: create(:gift, coins: 200))

    margin = described_class.new(days: 30).margin
    expect(margin[:stripe_fees_cents]).to be_within(0.01).of(1000 * 0.029 + 30)
    expect(margin[:creator_payouts_cents]).to be_within(0.01).of(200 * 1.0 * 0.5)
    expect(margin[:infra_cents]).to eq(7500.0)
    expect(margin[:profit_cents]).to be_within(0.01).of(1000 - 59 - 100 - 7500)
  end

  it "follows new users through the funnel" do
    newcomer = create(:user, :onboarded)
    other = create(:user, :onboarded)
    create(:like, liker: newcomer, likee: other)
    create(:like, liker: other, likee: newcomer)
    paid_purchase(newcomer)

    steps = described_class.new(days: 30).funnel.to_h { |s| [ s[:step], s[:users] ] }
    expect(steps).to include("Signed up" => 2, "Completed profile" => 2, "Rated someone" => 2, "Matched" => 2, "Opened checkout" => 1, "Bought coins" => 1)
  end

  it "measures day-N retention only for users old enough to have reached day N" do
    travel_to(Time.zone.parse("2026-10-05 12:00")) do
      @returning, @gone = create_list(:user, 2)
    end
    travel_to(Time.zone.parse("2026-10-06 12:00")) { visit(@returning) }

    travel_to(Time.zone.parse("2026-10-07 12:00")) do
      create(:user) # signed up today: can't count toward day 1 yet
      cohort = described_class.new.cohorts(weeks: 1).first
      expect(cohort[:users]).to eq(3)
      expect(cohort[:d1]).to eq(0.5)
      expect(cohort[:d7]).to be_nil
    end
  end

  it "compares today with the previous week" do
    6.downto(1) { |n| DailyMetric.create!(date: n.days.ago.to_date, revenue_cents: 1000) }
    paid_purchase(create(:user), cents: 500)
    trend = described_class.new.today_vs_week
    expect(trend[:today_cents]).to eq(500)
    expect(trend[:change]).to be < 0
  end
end
