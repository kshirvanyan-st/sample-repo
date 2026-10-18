require "rails_helper"

RSpec.describe "Payments", type: :request do
  let(:driver) { create(:driver_profile, :approved) }
  let(:top_up) { TopUp.create!(driver_profile: driver, amount: 5000, provider: "sandbox") }
  let(:adapter) { Payments::SandboxAdapter.new }

  def callback(body, signature: adapter.sign(body))
    post payments_callback_path("sandbox"), params: body, headers: { "Content-Type" => "application/json", Payments::SandboxAdapter::SIGNATURE_HEADER => signature }
  end

  def paid_body(event_id: "evt-1", amount: 5000)
    { event_id: event_id, status: "paid", order_id: top_up.id, payment_id: "pay-1", amount: amount }.to_json
  end

  it "credits a top-up from a signed callback, once" do
    callback(paid_body)
    expect(response).to have_http_status(:ok)
    callback(paid_body)                       # redelivered
    callback(paid_body(event_id: "evt-2"))    # a second "paid" for the same order
    expect(top_up.reload).to be_paid
    expect(driver.reload.balance).to eq(5000)
    expect(driver.ledger_entries.top_up.count).to eq(1)
  end

  it "rejects a bad signature or a wrong amount" do
    callback(paid_body, signature: "forged")
    expect(response).to have_http_status(:bad_request)
    callback(paid_body(amount: 50_000))
    expect(response).to have_http_status(:bad_request)
    expect(driver.reload.balance).to eq(0)
  end

  it "marks a declined payment as failed" do
    callback({ event_id: "evt-9", status: "failed", order_id: top_up.id, amount: 5000 }.to_json)
    expect(top_up.reload).to be_failed
  end

  describe "the driver's top-up flow with the sandbox bank" do
    before { sign_in_as(driver.user) }

    it "starts a top-up and pays it on the sandbox page" do
      post api_v1_driver_top_ups_path, params: { amount: 2000 }, as: :json
      expect(response).to have_http_status(:created)
      checkout = response.parsed_body["checkout_url"]

      get checkout
      expect(response.body).to include("2 000 ֏")
      patch checkout, params: { decision: "pay" }
      expect(response).to redirect_to(driver_app_path(top_up: "paid"))
      expect(driver.reload.balance).to eq(2000)
    end

    it "only accepts amounts between 1 000 and 50 000" do
      post api_v1_driver_top_ups_path, params: { amount: 100 }, as: :json
      expect(response.parsed_body["error"]).to eq("bad_amount")
    end

    it "won't open someone else's top-up" do
      other = TopUp.create!(driver_profile: create(:driver_profile, :approved), amount: 5000, provider: "sandbox")
      get payments_sandbox_path(other)
      expect(response).to have_http_status(:not_found)
    end

    it "is switched off without a payment provider" do
      allow(Rails.configuration.x.payments).to receive(:adapter).and_return(nil)
      post api_v1_driver_top_ups_path, params: { amount: 2000 }, as: :json
      expect(response.parsed_body["error"]).to eq("payments_off")
      get payments_sandbox_path(top_up)
      expect(response).to have_http_status(:not_found)
    end

    it "shows the balance and today's numbers" do
      DriverWallet.new(driver).debit!(150, kind: :adjustment, note: "test")
      get api_v1_driver_wallet_path
      expect(response.parsed_body).to include("balance" => -150, "needed" => 0, "commission_percent" => 10, "top_ups" => true)
      expect(response.parsed_body["entries"].sole).to include("kind" => "adjustment", "amount" => -150)
    end
  end
end
