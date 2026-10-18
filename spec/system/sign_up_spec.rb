require "rails_helper"

RSpec.describe "Sign up", type: :system do
  it "lets a visitor create an account and lands on the home page" do
    visit root_path
    click_link "Sign up"

    fill_in "Email address", with: "visitor@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_text("Welcome to Spark!")
    expect(page).to have_text("Signed in as visitor@example.com")
  end
end
