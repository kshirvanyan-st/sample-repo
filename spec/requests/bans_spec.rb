require "rails_helper"

RSpec.describe "Banned users", type: :request do
  let(:banned) { create(:user, :onboarded, profile_attributes: { display_name: "Banned Bob", gender: :male, looking_for: :women }) }
  let(:viewer) { create(:user, :onboarded, profile_attributes: { gender: :female, looking_for: :men }) }

  def ban(user)
    Moderation.new(create(:user, role: :admin)).ban!(user, reason: "Spam")
  end

  it "can't sign in" do
    ban(banned)
    sign_in_as(banned)
    expect(response).to redirect_to(new_session_path)
    expect(flash[:alert]).to eq("This account has been suspended.")
  end

  it "lose sessions that were already open" do
    sign_in_as(banned)
    get root_path
    expect(response).to have_http_status(:ok)

    ban(banned)
    get root_path
    expect(response.body).to include("Sign up") # signed-out home page
  end

  it "disappear from discovery, profiles and Liked me" do
    create(:like, liker: banned, likee: viewer)
    ban(banned)
    sign_in_as(viewer)

    expect(Discovery::Feed.new(viewer).candidates).not_to include(banned.profile)
    get profile_path(banned.profile)
    expect(response).to have_http_status(:not_found)
    get liked_me_path
    expect(response.body).not_to include("Banned Bob")
  end

  it "can't publish streams and their streams can't be watched" do
    banned.streaming_credentials!
    stream = create(:stream, :live, user: banned)
    ban(banned)

    sign_in_as(viewer)
    get stream_path(stream)
    expect(response).to have_http_status(:not_found)
  end

  it "suspended broadcasters can't go live" do
    banned.update!(streaming_suspended_at: Time.current)
    sign_in_as(banned)
    get go_live_path
    expect(response).to redirect_to(streams_path)
    post streams_path, params: { stream: { title: "Back!", category: "other" } }
    expect(banned.streams).to be_empty
  end
end
