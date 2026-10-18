require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /registration/new" do
    it "renders the sign-up form" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your account")
    end
  end

  describe "POST /registration" do
    let(:params) do
      { user: { email_address: "new@example.com", password: "password123", password_confirmation: "password123" } }
    end

    it "creates a user and signs them in" do
      expect { post registration_path, params: params }.to change(User, :count).by(1).and change(Session, :count).by(1)
      expect(response).to redirect_to(root_path)
      expect(cookies[:session_id]).to be_present
    end

    it "re-renders the form when invalid" do
      params[:user][:password_confirmation] = "mismatch"
      expect { post registration_path, params: params }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
