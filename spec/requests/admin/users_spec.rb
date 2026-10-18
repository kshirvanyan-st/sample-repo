require "rails_helper"

RSpec.describe "Admin users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:rider) { create(:user) }

  it "is hidden from everyone but admins" do
    get admin_users_path
    expect(response).to redirect_to(new_session_path)

    [ create(:user), create(:user, :driver), create(:user, :dispatcher) ].each do |user|
      sign_in_as(user)
      get admin_users_path
      expect(response).to have_http_status(:not_found)
      patch role_admin_user_path(rider), params: { role: "admin" }
      expect(response).to have_http_status(:not_found)
    end
    expect(rider.reload).to be_rider
  end

  context "as an admin" do
    before { sign_in_as(admin) }

    it "finds users by phone digits" do
      rider.update!(phone: "+37477987654")
      other = create(:user)
      get admin_users_path(q: "77 98")
      expect(response.body).to include(dom_id_for(rider))
      expect(response.body).not_to include(dom_id_for(other))
    end

    it "changes a role and logs it" do
      expect {
        patch role_admin_user_path(rider), params: { role: "driver" }
      }.to change { rider.reload.role }.to("driver").and change(ModerationAction, :count).by(1)
      expect(ModerationAction.last).to have_attributes(moderator: admin, user: rider, action: "change_role",
        details: { "from" => "rider", "to" => "driver" })
    end

    it "rejects an unknown role" do
      patch role_admin_user_path(rider), params: { role: "superuser" }
      expect(rider.reload).to be_rider
      expect(flash[:alert]).to be_present
    end

    it "bans a user, signing them out, and unbans them" do
      rider.sessions.create!
      post ban_admin_user_path(rider)
      expect(rider.reload).to be_banned
      expect(rider.sessions).to be_empty

      post unban_admin_user_path(rider)
      expect(rider.reload).not_to be_banned
      expect(ModerationAction.pluck(:action)).to eq(%w[ ban unban ])
    end

    it "can't demote or ban themselves" do
      patch role_admin_user_path(admin), params: { role: "rider" }
      post ban_admin_user_path(admin)
      expect(admin.reload).to be_admin
      expect(admin).not_to be_banned
    end
  end

  def dom_id_for(user)
    ActionView::RecordIdentifier.dom_id(user)
  end
end
