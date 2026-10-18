require "rails_helper"

RSpec.describe "Localization", type: :request do
  it "defaults to Armenian" do
    get root_path
    expect(response.body).to include('lang="hy"', "Շուտով Երևանում")
  end

  it "follows the browser's language" do
    get root_path, headers: { "Accept-Language" => "ru-RU,ru;q=0.9,en;q=0.8" }
    expect(response.body).to include('lang="ru"', "Скоро в Ереване")
  end

  it "switches with ?locale= and remembers the choice" do
    get root_path(locale: "en")
    expect(response.body).to include("Coming soon to Yerevan")

    get root_path
    expect(response.body).to include('lang="en"')
  end

  it "ignores unsupported locales" do
    get root_path(locale: "fr")
    expect(response.body).to include('lang="hy"')
  end
end
