require "rails_helper"

RSpec.describe "Stripe webhooks", type: :request do
  let(:secret) { "whsec_test" }
  let(:user) { create(:user) }
  let(:purchase) { create(:purchase, user: user, coin_pack: create(:coin_pack, coins: 500, bonus_coins: 50, price_cents: 499)) }

  around do |example|
    previous = Rails.configuration.x.stripe.webhook_secret
    Rails.configuration.x.stripe.webhook_secret = secret
    example.run
  ensure
    Rails.configuration.x.stripe.webhook_secret = previous
  end

  def deliver(type, object, id: "evt_#{SecureRandom.hex(4)}", signing_secret: secret)
    payload = { id: id, object: "event", type: type, data: { object: object } }.to_json
    timestamp = Time.now.to_i
    signature = Stripe::Webhook::Signature.compute_signature(Time.at(timestamp), payload, signing_secret)
    post "/stripe/webhooks", params: payload, headers: { "Stripe-Signature" => "t=#{timestamp},v1=#{signature}", "Content-Type" => "application/json" }
  end

  def checkout_session(overrides = {})
    { id: purchase.stripe_checkout_session_id, object: "checkout.session", client_reference_id: purchase.id.to_s,
      payment_status: "paid", amount_total: 499, currency: "usd", payment_intent: "pi_123" }.merge(overrides)
  end

  it "rejects unsigned or wrongly signed requests" do
    deliver("checkout.session.completed", checkout_session, signing_secret: "whsec_other")
    expect(response).to have_http_status(:bad_request)
    expect(user.reload.coin_balance).to eq(0)
  end

  it "credits the coins when checkout completes" do
    deliver("checkout.session.completed", checkout_session)
    expect(response).to have_http_status(:ok)
    expect(user.reload.coin_balance).to eq(550)
    expect(purchase.reload).to have_attributes(status: "paid", stripe_payment_intent_id: "pi_123")
  end

  it "handles a redelivered event only once" do
    2.times { deliver("checkout.session.completed", checkout_session, id: "evt_same") }
    expect(user.reload.coin_balance).to eq(550)
    expect(StripeEvent.where(stripe_event_id: "evt_same").count).to eq(1)
  end

  it "doesn't credit twice when both completed and async-succeeded arrive" do
    deliver("checkout.session.completed", checkout_session)
    deliver("checkout.session.async_payment_succeeded", checkout_session)
    expect(user.reload.coin_balance).to eq(550)
  end

  it "waits for delayed payment methods to actually pay" do
    deliver("checkout.session.completed", checkout_session(payment_status: "unpaid"))
    expect(user.reload.coin_balance).to eq(0)
    expect(purchase.reload).to be_pending
  end

  it "ignores sessions whose amount doesn't match the purchase" do
    deliver("checkout.session.completed", checkout_session(amount_total: 1))
    expect(user.reload.coin_balance).to eq(0)
  end

  it "marks abandoned checkouts expired" do
    deliver("checkout.session.expired", checkout_session(payment_status: "unpaid"))
    expect(purchase.reload).to be_expired
  end

  it "takes coins back when the charge is refunded" do
    deliver("checkout.session.completed", checkout_session)
    deliver("charge.refunded", { id: "ch_1", object: "charge", payment_intent: "pi_123" })
    expect(purchase.reload).to be_refunded
    expect(user.reload.coin_balance).to eq(0)
  end

  it "acknowledges events it doesn't handle" do
    deliver("customer.created", { id: "cus_1", object: "customer" })
    expect(response).to have_http_status(:ok)
  end
end
