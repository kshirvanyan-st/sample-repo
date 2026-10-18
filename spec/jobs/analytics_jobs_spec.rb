require "rails_helper"

RSpec.describe "Analytics jobs" do
  describe DailyMetricsJob do
    it "refreshes today and yesterday" do
      described_class.perform_now
      expect(DailyMetric.pluck(:date)).to contain_exactly(Date.current, Date.yesterday)
    end
  end

  describe RevenueAlertsJob do
    before { create(:user, role: :admin, email_address: "boss@example.com") }

    def day(date, revenue:, refunds: 0)
      DailyMetric.create!(date: date, revenue_cents: revenue, refunds_cents: refunds)
    end

    it "warns when yesterday's revenue fell well below the weekly average" do
      (2..8).each { |n| day(n.days.ago.to_date, revenue: 10_000) }
      allow(DailyMetricsJob).to receive(:perform_now)
      day(Date.yesterday, revenue: 2_000)

      expect { expect(described_class.perform_now.first).to include("80% below") }
        .to have_enqueued_mail(AdminMailer, :alerts)
    end

    it "warns about a high refund rate" do
      allow(DailyMetricsJob).to receive(:perform_now)
      day(3.days.ago.to_date, revenue: 100_000, refunds: 2_000)
      expect(described_class.perform_now).to include(a_string_including("Refunds are 2.0% of revenue"))
    end

    it "stays quiet with too little revenue to judge" do
      allow(DailyMetricsJob).to receive(:perform_now)
      day(3.days.ago.to_date, revenue: 1_000, refunds: 999)
      expect { expect(described_class.perform_now).to be_empty }.not_to have_enqueued_mail(AdminMailer, :alerts)
    end
  end

  it "emails admins, or ALERT_EMAILS when set" do
    create(:user, role: :admin, email_address: "boss@example.com")
    expect(AdminMailer.recipients).to eq([ "boss@example.com" ])
    mail = AdminMailer.alerts([ "Revenue dropped" ])
    expect(mail.subject).to eq("Spark alert: Revenue dropped")
    expect(mail.body.encoded).to include("/admin/revenue")
  end
end
