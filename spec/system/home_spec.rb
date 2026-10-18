require "rails_helper"

RSpec.describe "Home page", type: :system do
  it "switches language" do
    visit root_path
    expect(page).to have_text("Շուտով Երևանում")
    click_link "Русский"
    expect(page).to have_text("Скоро в Ереване")
    click_link "English"
    expect(page).to have_text("Coming soon to Yerevan")
  end
end
