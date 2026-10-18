require "rails_helper"

RSpec.describe "Admin finance", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:driver) { create(:driver_profile, :approved) }

  it "is only for admins" do
    sign_in_as(create(:user, :dispatcher))
    get admin_finance_path
    expect(response).to have_http_status(:not_found)
    post admin_driver_application_balance_path(driver), params: { kind: "top_up", amount: 5000, note: "x" }
    expect(driver.reload.balance).to eq(0)
  end

  context "as an admin" do
    before { sign_in_as(admin) }

    it "changes the commission and minimum balance, and logs it" do
      patch admin_settings_path, params: { business_setting: { commission_percent: 12, min_balance: -1000 } }
      expect(BusinessSetting.current).to have_attributes(commission_percent: 12, min_balance: -1000, updated_by: admin)
      expect(ModerationAction.last).to have_attributes(action: "change_settings", moderator: admin)
    end

    it "refuses settings out of range" do
      patch admin_settings_path, params: { business_setting: { commission_percent: 80, min_balance: 500 } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(BusinessSetting.current.commission_percent).to eq(10)
    end

    it "records cash paid at the office and corrections, with who and why" do
      post admin_driver_application_balance_path(driver), params: { kind: "top_up", amount: 5000, note: "Paid at the office" }
      post admin_driver_application_balance_path(driver), params: { kind: "adjustment", amount: -200, note: "Double payout" }
      expect(driver.reload.balance).to eq(4800)
      expect(driver.ledger_entries.pluck(:kind, :created_by_id)).to contain_exactly([ "top_up", admin.id ], [ "adjustment", admin.id ])
      expect(ModerationAction.pluck(:action)).to eq(%w[ balance_top_up balance_adjustment ])

      get admin_driver_application_balance_path(driver)
      expect(response.body).to include("Paid at the office", "Double payout")
    end

    it "needs a note, and a positive cash top-up" do
      post admin_driver_application_balance_path(driver), params: { kind: "top_up", amount: -100, note: "x" }
      post admin_driver_application_balance_path(driver), params: { kind: "adjustment", amount: 100, note: "" }
      expect(driver.reload.ledger_entries).to be_empty
    end

    it "adds up the ledger" do
      DriverWallet.new(driver).credit!(5000, kind: :top_up)
      DriverWallet.new(create(:driver_profile, :approved)).debit!(700, kind: :adjustment, note: "x")
      expect(Finance.summary(Time.current.all_day)).to include(top_ups: 5000, adjustments: -700)
      expect(Finance.balances).to include(owed_by_drivers: 700, driver_credit: 5000)
      get admin_finance_path
      expect(response.body).to include("5 000 ֏", "700 ֏")
    end
  end
end
