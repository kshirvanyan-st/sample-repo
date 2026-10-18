require "rails_helper"

RSpec.describe "Analytics events and experiments", type: :request do
  # Ahoy and field_test skip bots, and a request without a User-Agent counts as one.
  let(:browser) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 Safari/605.1.15" } }

  def sign_in_with_browser(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }, headers: browser
  end
  it "tracks sign-ups and attaches the visit to the user" do
    post registration_path, params: { user: { email_address: "new@example.com", password: "password123", password_confirmation: "password123" } }, headers: browser
    user = User.find_by!(email_address: "new@example.com")
    expect(Ahoy::Event.where(name: "signed_up", user: user)).to exist
    expect(Ahoy::Visit.where(user: user)).to exist
  end

  it "tracks ratings with their kind" do
    user = create(:user, :onboarded, profile_attributes: { gender: :male, looking_for: :women })
    other = create(:user, :onboarded, profile_attributes: { gender: :female, looking_for: :men })
    sign_in_with_browser(user)
    post likes_path, params: { profile_id: other.profile.id, kind: "superlike" }, headers: browser
    expect(Ahoy::Event.find_by!(name: "rated", user: user).properties).to include("kind" => "superlike")
  end

  it "assigns the coin store variant and converts it when coins are bought" do
    user = create(:user, :onboarded)
    sign_in_with_browser(user)
    get coins_path, headers: browser
    membership = FieldTest::Membership.find_by!(experiment: "coin_store_highlight", participant_id: user.id.to_s)
    expect(membership.variant).to be_in(%w[ control best_value_badge ])

    Purchase.start!(user, create(:coin_pack)).fulfill!
    expect(membership.reload).to be_converted
  end
end
