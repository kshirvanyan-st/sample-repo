require "rails_helper"

RSpec.describe "Profile", type: :request do
  let(:user) { create(:user, name: nil) }

  before { sign_in_as(user) }

  it "saves the name and language, and switches the site language" do
    patch profile_path, params: { user: { name: "Aram", locale: "ru" } }
    expect(response).to redirect_to(root_path)
    expect(user.reload).to have_attributes(name: "Aram", locale: "ru")

    get root_path
    expect(response.body).to include('lang="ru"')
  end

  it "requires a name" do
    patch profile_path, params: { user: { name: "", locale: "hy" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "can't change the role" do
    patch profile_path, params: { user: { name: "Aram", role: "admin" } }
    expect(user.reload).to be_rider
  end
end
