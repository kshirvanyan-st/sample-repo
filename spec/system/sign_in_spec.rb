require "rails_helper"

RSpec.describe "Signing in with a phone", type: :system do
  it "signs up, sets a name, saves home and switches to Russian" do
    visit root_path
    click_link "Մուտք հեռախոսահամարով"
    fill_in "Հեռախոսահամար", with: "091 123456"
    click_button "Ստանալ կոդը"

    expect(page).to have_text("+374 91 123456")
    fill_in "Կոդ", with: last_sms_code
    click_button "Մուտք"

    fill_in "Անուն", with: "Անի"
    select "Русский", from: "Լեզու"
    click_button "Պահպանել"
    expect(page).to have_text("Профиль сохранён.")

    click_link "Мои места"
    find("li", text: "Дом").click_link("Добавить")
    fill_in "Адрес", with: "ул. Туманяна 5"
    click_button "Сохранить место"
    expect(page).to have_text("Место сохранено.")
    expect(page).to have_text("ул. Туманяна 5")

    click_button "Выйти"
    expect(page).to have_link("Войти")
  end
end
