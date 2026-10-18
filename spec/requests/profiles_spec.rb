require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, :onboarded) }
  let(:other) { create(:user, :onboarded) }

  before { sign_in_as(user) }

  it "shows another user's profile with only approved photos" do
    pending_photo = create(:photo, profile: other.profile)
    get profile_path(other.profile)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(other.profile.display_name)
    expect(response.body).to include("Follow")
    expect(response.body.scan("<img").size).to eq(1)
    expect(pending_photo).to be_pending
  end

  it "hides profiles that haven't finished onboarding" do
    unfinished = create(:profile)
    get profile_path(unfinished)
    expect(response).to have_http_status(:not_found)
  end

  it "updates your own profile" do
    patch my_profile_path, params: { profile: { bio: "New bio" } }
    expect(response).to redirect_to(profile_path(user.profile))
    expect(user.profile.reload.bio).to eq("New bio")
  end

  it "re-renders the edit form when invalid" do
    patch my_profile_path, params: { profile: { display_name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "requires sign-in" do
    delete session_path
    get profile_path(other.profile)
    expect(response).to redirect_to(new_session_path)
  end
end
