require "rails_helper"

RSpec.describe "Follows", type: :request do
  let(:user) { create(:user, :onboarded) }
  let(:other) { create(:user, :onboarded) }

  before { sign_in_as(user) }

  it "follows and unfollows" do
    post profile_follow_path(other.profile)
    expect(user.following?(other)).to be(true)

    delete profile_follow_path(other.profile)
    expect(user.following?(other)).to be(false)
  end

  it "replaces the button with a Turbo Stream" do
    post profile_follow_path(other.profile), as: :turbo_stream
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(response.body).to include("Unfollow")
  end

  it "can't follow yourself" do
    post profile_follow_path(user.profile)
    expect(response).to have_http_status(:unprocessable_content)
  end
end
