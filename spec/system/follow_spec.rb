require "rails_helper"

RSpec.describe "Following", type: :system do
  it "follows another user from their profile" do
    user = create(:user, :onboarded)
    other = create(:user, :onboarded)

    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"

    visit profile_path(other.profile)
    click_button "Follow"

    expect(page).to have_button("Unfollow")
    expect(page).to have_text("1 follower")
  end
end
