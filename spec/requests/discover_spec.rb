require "rails_helper"

RSpec.describe "Discover and likes", type: :request do
  let(:user) { create(:user, :onboarded, profile_attributes: { gender: :male, looking_for: :women }) }
  let!(:ani) { create(:user, :onboarded, profile_attributes: { display_name: "Ani", gender: :female, looking_for: :men }) }

  before { sign_in_as(user) }

  it "shows the next candidate" do
    get discover_path
    expect(response.body).to include("Ani")
  end

  it "shows an empty state when nobody is left" do
    create(:like, liker: user, likee: ani)
    get discover_path
    expect(response.body).to include("That's everyone for now")
  end

  it "likes and returns the next card as a Turbo Stream" do
    post likes_path, params: { profile_id: ani.profile.id, kind: "like" }, as: :turbo_stream
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(response.body).to include("That's everyone for now")
    expect(user.likes_given.last).to have_attributes(likee: ani, kind: "like")
  end

  it "records skips" do
    post likes_path, params: { profile_id: ani.profile.id, kind: "skip" }
    expect(user.likes_given.last).to be_skip
    expect(response).to redirect_to(discover_path)
  end

  it "announces a match" do
    create(:like, liker: ani, likee: user)
    post likes_path, params: { profile_id: ani.profile.id, kind: "like" }, as: :turbo_stream
    expect(response.body).to include("It&#39;s a match with Ani!")
    expect(user.matched_with?(ani)).to be(true)
  end

  it "rejects unknown kinds" do
    post likes_path, params: { profile_id: ani.profile.id, kind: "love" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "can't rate someone who blocked you" do
    create(:block, blocker: ani, blocked: user)
    post likes_path, params: { profile_id: ani.profile.id, kind: "like" }
    expect(response).to have_http_status(:not_found)
  end

  it "ignores a second rating of the same person" do
    post likes_path, params: { profile_id: ani.profile.id, kind: "skip" }
    post likes_path, params: { profile_id: ani.profile.id, kind: "like" }
    expect(user.likes_given.sole).to be_skip
  end
end
