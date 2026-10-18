require "rails_helper"

RSpec.describe "Becoming a driver", type: :system do
  let(:file) { Rails.root.join("spec/fixtures/files/document.png") }

  def sign_in(user)
    visit new_session_path(locale: "en")
    fill_in "Phone number", with: user.phone
    click_button "Send code"
    fill_in "Code", with: last_sms_code(user.phone)
    click_button "Sign in"
  end

  it "applies, gets approved by an admin, and sees the result" do
    rider = create(:user, name: "Aram", locale: "en")
    sign_in(rider)
    click_link "Drive with us"

    fill_in "License number", with: "AB123456"
    fill_in "License valid until", with: 2.years.from_now.to_date
    %w[ License,\ front License,\ back Passport\ or\ ID\ card Photo\ of\ your\ face ].each { |label| attach_file label, file }
    click_button "Save draft"
    expect(page).to have_text("Draft saved.")

    click_link "Edit application"
    fill_in "Make", with: "Hyundai"
    fill_in "Model", with: "Elantra"
    fill_in "Color", with: "Black"
    fill_in "Year", with: 2020
    fill_in "Plate number", with: "35 ОС 777"
    fill_in "Registration valid until", with: 1.year.from_now.to_date
    fill_in "Insurance valid until", with: 1.year.from_now.to_date
    [ "Registration certificate", "Insurance policy", "Photo of the car" ].each { |label| attach_file label, file }
    click_button "Submit for review"
    expect(page).to have_text("Under review")
    expect(page).to have_text("35 OC 777")
    click_button "Sign out"

    sign_in(create(:user, :admin, locale: "en"))
    visit admin_driver_applications_path
    click_link "Review"
    expect(page).to have_css("img[alt='Photo of the car']")
    click_button "Approve"
    expect(page).to have_text("Aram is approved.")
    click_button "Sign out"

    travel PhoneVerification::RESEND_COOLDOWN + 1.second # so the same number gets a new code
    sign_in(rider)
    click_link "Driver"
    expect(page).to have_text("You're approved to drive.")
  end
end
