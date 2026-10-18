require "rails_helper"

RSpec.describe "Matching", type: :system do
  def sign_in(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end

  it "matches two people who like each other" do
    aram = create(:user, :onboarded, profile_attributes: { display_name: "Aram", gender: :male, looking_for: :women })
    ani = create(:user, :onboarded, profile_attributes: { display_name: "Ani", gender: :female, looking_for: :men })

    sign_in(aram)
    within("nav", match: :first) { click_link "Discover" }
    expect(page).to have_text("Ani,")
    click_button "♥ Like"
    expect(page).to have_text("That's everyone for now")
    click_button "Sign out"

    sign_in(ani)
    within("nav", match: :first) { click_link "Liked me" }
    expect(page).to have_text("Aram")
    click_button "♥ Like back"
    expect(page).to have_text("It's a match with Aram!")
    click_button "Sign out"

    sign_in(aram)
    within("nav", match: :first) { click_link "Matches" }
    expect(page).to have_text("Ani")
  end
end
