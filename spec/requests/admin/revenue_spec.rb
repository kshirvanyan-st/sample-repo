require "rails_helper"

RSpec.describe "Revenue dashboard", type: :request do
  it "is for admins only" do
    sign_in_as(create(:user, :onboarded, role: :moderator))
    get admin_revenue_path
    expect(response).to have_http_status(:not_found)
  end

  it "renders the numbers" do
    admin = create(:user, :onboarded, role: :admin)
    purchase = Purchase.start!(admin, create(:coin_pack, name: "Best value", price_cents: 999))
    purchase.fulfill!
    sign_in_as(admin)

    get admin_revenue_path(days: 7)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Revenue per day", "$9.99", "Funnel", "Retention", "Coin Store Highlight", "Best value")
  end

  it "keeps Blazer and the experiments dashboard behind the admin check" do
    sign_in_as(create(:user, :onboarded))
    get "/admin/blazer"
    expect(response).to have_http_status(:not_found)
    get "/admin/experiments"
    expect(response).to have_http_status(:not_found)
  end

  it "lets admins open Blazer and the experiments dashboard" do
    sign_in_as(create(:user, :onboarded, role: :admin))
    get "/admin/blazer"
    expect(response).to have_http_status(:ok)
    get "/admin/experiments"
    expect(response).to have_http_status(:ok)
  end
end
