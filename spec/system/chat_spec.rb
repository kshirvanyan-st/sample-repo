require "rails_helper"

RSpec.describe "Chat", type: :system do
  def sign_in(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end

  it "starts a chat from Matches and both people see the messages" do
    aram = create(:user, :onboarded, profile_attributes: { display_name: "Aram" })
    ani = create(:user, :onboarded, profile_attributes: { display_name: "Ani" })
    Match.between!(aram, ani)

    sign_in(aram)
    within("nav", match: :first) { click_link "Matches" }
    click_button "Message"
    expect(page).to have_text("You matched with Ani. Say hi!")
    fill_in "Message", with: "Hi Ani!"
    click_button "Send"
    expect(page).to have_text("Hi Ani!")
    click_button "Sign out"

    sign_in(ani)
    within("nav", match: :first) { expect(page).to have_css(".chats-count", text: "1") }
    within("nav", match: :first) { click_link "Chats" }
    expect(page).to have_text("Hi Ani!")
    click_link "Aram"
    fill_in "Message", with: "Hey Aram"
    click_button "Send"
    expect(page).to have_text("Hey Aram")
    within("nav", match: :first) { expect(page).to have_no_css(".chats-count", text: /\d/) }
  end
end
