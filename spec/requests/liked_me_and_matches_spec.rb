require "rails_helper"

RSpec.describe "Liked me and matches", type: :request do
  let(:user) { create(:user, :onboarded) }
  let(:admirer) { create(:user, :onboarded, profile_attributes: { display_name: "Admirer" }) }
  let(:rated) { create(:user, :onboarded, profile_attributes: { display_name: "Already rated" }) }

  before { sign_in_as(user) }

  it "lists people who liked you that you haven't rated" do
    create(:like, liker: admirer, likee: user)
    create(:like, liker: rated, likee: user, kind: :superlike)
    create(:like, liker: user, likee: rated, kind: :skip)

    get liked_me_path
    expect(response.body).to include("Admirer")
    expect(response.body).not_to include("Already rated")
  end

  it "removes the card and matches when liking back" do
    create(:like, liker: admirer, likee: user)
    post likes_path, params: { profile_id: admirer.profile.id, kind: "like", source: "liked_me" }, as: :turbo_stream
    expect(response.body).to include(%(action="remove"))
    expect(response.body).to include("match with Admirer")
    expect(response.body).to include(%(<turbo-stream action="update" targets=".matches-count"><template>1</template>))
    expect(response.body).to include(%(<turbo-stream action="update" targets=".liked-me-count"><template>0</template>))
  end

  it "lists matches and unmatches" do
    match = Match.between!(user, admirer)
    get matches_path
    expect(response.body).to include("Admirer")

    delete match_path(match)
    expect(response).to redirect_to(matches_path)
    expect(Match.exists?(match.id)).to be(false)
  end

  it "can't unmatch other people's matches" do
    match = Match.between!(admirer, rated)
    delete match_path(match)
    expect(response).to have_http_status(:not_found)
  end
end
