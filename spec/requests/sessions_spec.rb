require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  it "signs in with valid credentials" do
    sign_in_as(user)
    expect(response).to redirect_to(root_url)
    expect(cookies[:session_id]).to be_present
  end

  it "rejects invalid credentials" do
    sign_in_as(user, password: "wrong-password")
    expect(response).to redirect_to(new_session_path)
  end

  it "signs out" do
    sign_in_as(user)
    expect { delete session_path }.to change(Session, :count).by(-1)
    expect(response).to redirect_to(new_session_path)
  end
end
