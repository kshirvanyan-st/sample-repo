require "rails_helper"

RSpec.describe "Blocking and reporting", type: :request do
  let(:user) { create(:user, :onboarded) }
  let(:other) { create(:user, :onboarded, profile_attributes: { display_name: "Other" }) }

  before { sign_in_as(user) }

  it "blocks someone, removing the match and hiding you from them" do
    Match.between!(user, other)
    post profile_block_path(other.profile)
    expect(response).to redirect_to(discover_path)
    expect(user.matched_with?(other)).to be(false)

    get profile_path(other.profile)
    expect(response.body).to include("Unblock")

    delete session_path
    sign_in_as(other)
    get profile_path(user.profile)
    expect(response).to have_http_status(:not_found)
  end

  it "unblocks" do
    create(:block, blocker: user, blocked: other)
    delete profile_block_path(other.profile)
    expect(user.blocking?(other)).to be(false)
  end

  it "can't follow someone who blocked you" do
    create(:block, blocker: other, blocked: user)
    post profile_follow_path(other.profile)
    expect(response).to have_http_status(:not_found)
  end

  it "files a report" do
    get new_profile_report_path(other.profile)
    expect(response).to have_http_status(:ok)

    expect {
      post profile_reports_path(other.profile), params: { report: { reason: "fake", details: "Stolen photos" } }
    }.to change(Report, :count).by(1)
    expect(Report.last).to have_attributes(reporter: user, reported: other, reason: "fake")
    expect(response).to redirect_to(profile_path(other.profile))
  end

  it "rejects invalid reports" do
    post profile_reports_path(other.profile), params: { report: { reason: "fake", details: "x" * 1001 } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "updates discovery preferences" do
    patch my_profile_path, params: { profile: { age_min: 25, age_max: 35, max_distance_km: 20 } }
    expect(user.profile.reload).to have_attributes(age_min: 25, age_max: 35, max_distance_km: 20)
  end
end
