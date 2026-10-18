module Analytics
  # Everything on /admin/revenue. Daily totals come from DailyMetric; funnels, cohorts and
  # retention are computed from the source tables because they span days.
  class Revenue
    # Cost assumptions for gross margin, overridable per deployment.
    STRIPE_FEE_RATE = ENV.fetch("STRIPE_FEE_PERCENT", "2.9").to_f / 100
    STRIPE_FEE_FIXED_CENTS = ENV.fetch("STRIPE_FEE_FIXED_CENTS", "30").to_i
    CREATOR_PAYOUT_SHARE = ENV.fetch("CREATOR_PAYOUT_SHARE", "0.5").to_f # of the value of gifted coins
    INFRA_MONTHLY_COST_CENTS = ENV.fetch("INFRA_MONTHLY_COST_CENTS", "7500").to_i

    FUNNEL_STEPS = [ "Signed up", "Completed profile", "Rated someone", "Matched", "Watched a stream", "Opened checkout", "Bought coins" ].freeze

    attr_reader :days

    def initialize(days: 30)
      @days = days
      DailyMetric.compute!(Date.current) # today is always fresh
    end

    def range
      (days - 1).days.ago.to_date..Date.current
    end

    def daily
      @daily ||= begin
        rows = DailyMetric.between(range).index_by(&:date)
        range.map { |date| rows[date] || DailyMetric.new(date: date) }
      end
    end

    def totals
      @totals ||= begin
        sum = ->(column) { daily.sum { |row| row.public_send(column) } }
        revenue = sum.(:revenue_cents)
        refunds = sum.(:refunds_cents)
        payers = paid_purchases.distinct.count(:user_id)
        active = Ahoy::Visit.where(started_at: period).where.not(user_id: nil).distinct.count(:user_id)

        {
          revenue_cents: revenue,
          refunds_cents: refunds,
          purchases: sum.(:purchases),
          payers: payers,
          active_users: active,
          payer_conversion: ratio(payers, active),
          arpu_cents: ratio(revenue, active),
          arppu_cents: ratio(revenue, payers),
          refund_rate: ratio(refunds, revenue),
          coins_purchased: sum.(:coins_purchased),
          coins_spent: sum.(:coins_spent),
          gift_coins: sum.(:gift_coins),
          unspent_coins: User.sum(:coin_balance),
          viewer_hours: sum.(:viewer_seconds) / 3600.0
        }
      end
    end

    # Today against the average of the 7 days before it.
    def today_vs_week
      today = daily.last.revenue_cents
      previous = daily[-8..-2].to_a
      average = previous.empty? ? 0 : previous.sum(&:revenue_cents) / previous.size.to_f
      { today_cents: today, week_average_cents: average, change: average.zero? ? nil : (today - average) / average }
    end

    # Revenue minus Stripe fees, the creators' share of gifted coins, and servers.
    def margin
      t = totals
      coin_value_cents = ratio(t[:revenue_cents], t[:coins_purchased]) # average paid per coin
      stripe_fees = t[:revenue_cents] * STRIPE_FEE_RATE + t[:purchases] * STRIPE_FEE_FIXED_CENTS
      creator_payouts = t[:gift_coins] * coin_value_cents * CREATOR_PAYOUT_SHARE
      infra = INFRA_MONTHLY_COST_CENTS * days / 30.0
      net = t[:revenue_cents] - t[:refunds_cents]
      profit = net - stripe_fees - creator_payouts - infra

      {
        net_revenue_cents: net, stripe_fees_cents: stripe_fees, creator_payouts_cents: creator_payouts,
        infra_cents: infra, profit_cents: profit, margin: ratio(profit, net),
        infra_per_viewer_hour_cents: ratio(infra, t[:viewer_hours])
      }
    end

    # How far people who signed up in the period got.
    def funnel
      cohort = User.where(created_at: period)
      ids = cohort.select(:id)
      counts = [
        cohort.count,
        Profile.where(user_id: ids).where.not(onboarded_at: nil).count,
        Like.where(liker_id: ids).distinct.count(:liker_id),
        User.where(id: ids).where(id: Match.select(:user_a_id)).or(User.where(id: ids).where(id: Match.select(:user_b_id))).count,
        Ahoy::Event.where(name: "stream_watched", user_id: ids).distinct.count(:user_id),
        Purchase.where(user_id: ids).distinct.count(:user_id),
        Purchase.where(user_id: ids, status: %i[ paid refunded ]).distinct.count(:user_id)
      ]
      FUNNEL_STEPS.zip(counts).map { |step, count| { step: step, users: count, share: ratio(count, counts.first) } }
    end

    # Weekly signup cohorts: size, share active 1, 7 and 30 days after signing up,
    # and revenue per user so far (LTV to date).
    def cohorts(weeks: 6)
      (0...weeks).map do |offset|
        week = offset.weeks.ago.all_week
        users = User.where(created_at: week)
        size = users.count
        retained = ->(n) { retention(users, n) }
        {
          week: week.begin.to_date, users: size,
          d1: retained.(1), d7: retained.(7), d30: retained.(30),
          ltv_cents: ratio(Purchase.where(user_id: users.select(:id), status: :paid).sum(:amount_cents), size)
        }
      end
    end

    def top_broadcasters(limit: 5)
      totals = GiftTransaction.where(created_at: period).group(:recipient_id).order(Arel.sql("SUM(coins) DESC")).limit(limit).sum(:coins)
      users = User.includes(:profile).where(id: totals.keys).index_by(&:id)
      totals.map { |id, coins| { user: users[id], coins: coins } }
    end

    def coin_packs
      Purchase.where(paid_at: period, status: %i[ paid refunded ]).joins(:coin_pack).group("coin_packs.name")
        .order(Arel.sql("SUM(purchases.amount_cents) DESC")).pluck("coin_packs.name", Arel.sql("COUNT(*)"), Arel.sql("SUM(purchases.amount_cents)"))
    end

    def experiments
      FieldTest::Experiment.all.map { |experiment| { experiment: experiment, results: experiment.results } }
    end

    private
      def period
        range.first.beginning_of_day..range.last.end_of_day
      end

      def paid_purchases
        Purchase.where(paid_at: period, status: %i[ paid refunded ])
      end

      # Share of users active on day N, counting only those who signed up at least N days ago
      # (nil when nobody has reached day N yet).
      def retention(users, n)
        eligible = users.where(created_at: ...(Date.current - n).beginning_of_day)
        count = eligible.count
        count.zero? ? nil : ratio(active_on_day(eligible, n), count)
      end

      # Users (of a relation) with a visit on calendar day N after their signup day.
      def active_on_day(users, n)
        Ahoy::Visit.joins(:user).merge(users)
          .where("ahoy_visits.started_at::date = users.created_at::date + CAST(? AS integer)", n)
          .distinct.count(:user_id)
      end

      def ratio(numerator, denominator)
        denominator.to_f.zero? ? 0 : numerator / denominator.to_f
      end
  end
end
