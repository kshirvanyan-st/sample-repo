require "rails_helper"

RSpec.describe "Admin driver applications", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:profile) { create(:driver_profile, :submitted) }

  it "is only for admins" do
    sign_in_as(create(:user, :dispatcher))
    get admin_driver_applications_path
    expect(response).to have_http_status(:not_found)
    post approve_admin_driver_application_path(profile)
    expect(profile.reload).to be_submitted
  end

  context "as an admin" do
    before { sign_in_as(admin) }

    it "lists the queue, oldest first" do
      newer = create(:driver_profile, :submitted, submitted_at: 1.minute.ago)
      older = create(:driver_profile, :submitted, submitted_at: 1.day.ago)
      create(:driver_profile, :complete) # a draft isn't in the queue
      get admin_driver_applications_path
      expect(response.body.index(ActionView::RecordIdentifier.dom_id(older))).to be < response.body.index(ActionView::RecordIdentifier.dom_id(newer))
      expect(response.body.scan(/id="driver_profile_\d+"/).size).to eq(2)
    end

    it "shows an application with its documents" do
      get admin_driver_application_path(profile)
      expect(response.body).to include(document_path(profile.selfie.attachment), profile.vehicle.plate_number)
    end

    it "approves a driver, makes them a driver, logs it and texts them" do
      perform_enqueued_jobs do
        post approve_admin_driver_application_path(profile)
      end
      expect(profile.reload).to be_approved
      expect(profile.user.reload).to be_driver
      expect(ModerationAction.last).to have_attributes(moderator: admin, user: profile.user, action: "approve_driver")
      expect(SmsSender::TestAdapter.deliveries.last).to have_attributes(to: profile.user.phone)
    end

    it "asks for changes with a note" do
      post request_changes_admin_driver_application_path(profile), params: { note: "Selfie is blurry" }
      expect(profile.reload).to have_attributes(status: "needs_changes", review_note: "Selfie is blurry")
      expect(ModerationAction.last.details).to include("note" => "Selfie is blurry")
    end

    it "needs a note to reject" do
      post reject_admin_driver_application_path(profile), params: { note: " " }
      expect(profile.reload).to be_submitted
      post reject_admin_driver_application_path(profile), params: { note: "Fake documents" }
      expect(profile.reload).to be_rejected
      expect(profile.user.reload).to be_rider
    end

    it "suspends an approved driver" do
      approved = create(:driver_profile, :approved)
      post suspend_admin_driver_application_path(approved), params: { note: "Complaints" }
      expect(approved.reload).to be_suspended
    end

    it "refuses a decision that doesn't fit the status" do
      approved = create(:driver_profile, :approved)
      post reject_admin_driver_application_path(approved), params: { note: "No" }
      expect(approved.reload).to be_approved
      expect(flash[:alert]).to be_present
    end
  end
end
