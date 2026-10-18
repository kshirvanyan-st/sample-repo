require "rails_helper"

RSpec.describe "Sign up and onboarding", type: :system do
  it "lets a visitor create an account and finish their profile" do
    visit root_path
    click_link "Sign up"

    fill_in "Email address", with: "visitor@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_text("Welcome to Spark!")
    fill_in "Name", with: "Ani"
    fill_in "Birthdate", with: "1998-04-02"
    select "Female", from: "I am"
    select "Men", from: "Looking for"
    click_button "Continue"

    fill_in "City", with: "Yerevan"
    fill_in "About me", with: "Hiking and jazz"
    click_button "Continue"

    attach_file "Photos", Rails.root.join("spec/fixtures/files/photo.jpg")
    click_button "Finish"

    expect(page).to have_text("Your profile is ready!")
    expect(page).to have_text("Hi, Ani!")
  end
end
