require "rails_helper"

RSpec.describe "Coins, purchases and gifts", type: :request do
  let(:user) { create(:user, :onboarded) }
  let!(:pack) { create(:coin_pack, name: "Popular", coins: 500, bonus_coins: 50, price_cents: 499) }

  before { sign_in_as(user) }

  it "shows the balance, packs and history" do
    give_coins(user, 42)
    get coins_path
    expect(response.body).to include("Popular", "550", "$4.99", "+42")
  end

  describe "buying coins" do
    around do |example|
      Stripe.api_key = "sk_test_123"
      example.run
    ensure
      Stripe.api_key = nil
    end

    it "starts a Stripe Checkout session priced from the server-side pack" do
      session = Stripe::Checkout::Session.construct_from(id: "cs_test_abc", url: "https://checkout.stripe.com/c/pay/cs_test_abc")
      expect(Stripe::Checkout::Session).to receive(:create) do |params|
        expect(params[:line_items].sole[:price_data]).to include(currency: "usd", unit_amount: 499)
        expect(params[:client_reference_id]).to eq(Purchase.last.id.to_s)
        session
      end

      post purchases_path, params: { coin_pack_id: pack.id, price_cents: 1 }
      expect(response).to redirect_to("https://checkout.stripe.com/c/pay/cs_test_abc")
      expect(Purchase.last).to have_attributes(user: user, amount_cents: 499, coins: 550, stripe_checkout_session_id: "cs_test_abc", status: "pending")
      expect(user.reload.coin_balance).to eq(0)
    end

    it "explains when Stripe fails" do
      allow(Stripe::Checkout::Session).to receive(:create).and_raise(Stripe::APIConnectionError, "down")
      post purchases_path, params: { coin_pack_id: pack.id }
      expect(response).to redirect_to(coins_path)
      expect(flash[:alert]).to include("couldn't start the payment")
    end

    it "won't sell inactive packs" do
      pack.update!(active: false)
      post purchases_path, params: { coin_pack_id: pack.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  it "doesn't sell coins without Stripe outside development" do
    post purchases_path, params: { coin_pack_id: pack.id }
    expect(flash[:alert]).to include("aren't available")
    expect(user.reload.coin_balance).to eq(0)
  end

  describe "gifts" do
    let(:stream) { create(:stream, :live) }
    let(:rose) { create(:gift, name: "Rose", coins: 10) }

    it "sends a gift" do
      give_coins(user, 50)
      post stream_gifts_path(stream), params: { gift_id: rose.id }, as: :turbo_stream
      expect(response).to have_http_status(:no_content)
      expect(user.reload.coin_balance).to eq(40)
    end

    it "asks for more coins when the balance is too low" do
      post stream_gifts_path(stream), params: { gift_id: rose.id }, as: :turbo_stream
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("You need 10 coins", "Get coins")
    end

    it "can't gift someone who blocked you" do
      give_coins(user, 50)
      create(:block, blocker: stream.user, blocked: user)
      post stream_gifts_path(stream), params: { gift_id: rose.id }
      expect(response).to have_http_status(:not_found)
      expect(user.reload.coin_balance).to eq(50)
    end

    it "shows the gift bar and leaderboard to viewers" do
      rose
      get stream_path(stream)
      expect(response.body).to include("Send a gift", "Rose", "Top gifters")
    end
  end

  it "shows earnings" do
    stream = create(:stream, :live, user: user)
    GiftTransaction.send!(sender: give_coins(create(:user, :onboarded, profile_attributes: { display_name: "Generous" }), 100), stream: stream, gift: create(:gift, name: "Teddy", coins: 50))
    get earnings_path
    expect(response.body).to include("50", "Generous", "Teddy")
  end
end
