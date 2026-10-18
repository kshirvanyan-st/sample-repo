require "rails_helper"

RSpec.describe "Admin area", type: :request do
  let(:moderator) { create(:user, :onboarded, role: :moderator) }
  let(:member) { create(:user, :onboarded) }
  let(:target) { create(:user, :onboarded, profile_attributes: { display_name: "Spammy" }) }

  it "is hidden from regular members" do
    sign_in_as(member)
    get admin_root_path
    expect(response).to have_http_status(:not_found)
    post ban_admin_user_path(target), params: { reason: "x" }
    expect(response).to have_http_status(:not_found)
    expect(target.reload).not_to be_banned
  end

  context "as a moderator" do
    before { sign_in_as(moderator) }

    it "shows the dashboard and every queue" do
      create(:report, reported: target, reason: :fake, details: "Stolen photos")
      [ admin_root_path, admin_reports_path, admin_photos_path, admin_streams_path, admin_users_path, admin_user_path(target), admin_moderation_actions_path ].each do |path|
        get path
        expect(response).to have_http_status(:ok), path
      end
      get admin_reports_path
      expect(response.body).to include("Spammy", "Fake", "Stolen photos")
    end

    it "searches users" do
      target
      get admin_users_path(q: "spam")
      expect(response.body).to include("Spammy")
      get admin_users_path(q: "nobody-matches")
      expect(response.body).not_to include("Spammy")
    end

    it "bans and unbans" do
      post ban_admin_user_path(target), params: { reason: "Scam messages" }
      expect(response).to redirect_to(admin_user_path(target))
      expect(target.reload).to be_banned

      post unban_admin_user_path(target)
      expect(target.reload).not_to be_banned
    end

    it "dismisses a report" do
      report = create(:report, reported: target)
      patch admin_report_path(report)
      expect(report.reload).to be_resolved
    end

    it "reviews photos" do
      photo = create(:photo, profile: target.profile)
      patch admin_photo_path(photo, decision: "reject")
      expect(photo.reload).to be_rejected
      patch admin_photo_path(photo, decision: "nonsense")
      expect(flash[:alert]).to eq("Unknown decision")
    end

    it "ends and suspends a live stream" do
      stream = create(:stream, :live, user: target)
      allow_any_instance_of(MediaServer).to receive(:kick_publisher)
      post shut_down_admin_stream_path(stream, suspend: "1")
      expect(stream.reload).to be_ended
      expect(target.reload).to be_streaming_suspended
    end

    it "can't change roles" do
      patch role_admin_user_path(target), params: { role: "admin" }
      expect(flash[:alert]).to eq("Only admins can change roles")
      expect(target.reload).to be_member
    end
  end

  it "lets admins change roles" do
    sign_in_as(create(:user, :onboarded, role: :admin))
    patch role_admin_user_path(target), params: { role: "moderator" }
    expect(target.reload).to be_moderator
  end
end
