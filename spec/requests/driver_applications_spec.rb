require "rails_helper"

RSpec.describe "Driver applications", type: :request do
  let(:user) { create(:user) }

  def upload(name = "document.png", type = "image/png")
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files", name), type)
  end

  def complete_params
    { license_number: "AB123456", license_expires_on: 2.years.from_now.to_date,
      **DriverProfile::DOCUMENTS.index_with { upload },
      vehicle_attributes: { make: "Toyota", model: "Prius", color: "Silver", year: 2019, plate_number: "35os555",
                            vehicle_class: "economy", registration_expires_on: 1.year.from_now.to_date,
                            insurance_expires_on: 1.year.from_now.to_date, **Vehicle::DOCUMENTS.index_with { upload } } }
  end

  before { sign_in_as(user) }

  it "starts with the form" do
    get driver_application_path
    expect(response).to redirect_to(edit_driver_application_path)
  end

  it "saves a draft, then submits it" do
    patch driver_application_path, params: { driver_profile: { license_number: "AB123456", license_front: upload } }
    expect(response).to redirect_to(driver_application_path)
    profile = user.reload.driver_profile
    expect(profile).to be_draft
    expect(profile.license_front).to be_attached

    params = complete_params.except(:license_front)
    patch driver_application_path, params: { driver_profile: params, submit_application: "1" }
    expect(profile.reload).to be_submitted
    expect(profile.vehicle.plate_number).to eq("35 OS 555")
    expect(profile.license_front).to be_attached # an empty file field doesn't remove an upload
  end

  it "keeps the uploads when submitting fails on a missing field" do
    patch driver_application_path, params: { driver_profile: complete_params.except(:license_number), submit_application: "1" }
    expect(response).to have_http_status(:unprocessable_content)
    profile = user.reload.driver_profile
    expect(profile).to be_draft
    expect(profile.missing_documents).to be_empty
  end

  it "can't be changed while under review" do
    create(:driver_profile, :submitted, user: user)
    get edit_driver_application_path
    expect(response).to redirect_to(driver_application_path)
    patch driver_application_path, params: { driver_profile: { license_number: "NEW" } }
    expect(user.driver_profile.reload.license_number).to eq("AB123456")
  end

  it "shows the reviewer's note and lets the driver resubmit" do
    profile = create(:driver_profile, :complete, user: user, status: :needs_changes, review_note: "The selfie is blurry")
    get edit_driver_application_path
    expect(response.body).to include("The selfie is blurry")

    patch driver_application_path, params: { driver_profile: { selfie: upload }, submit_application: "1" }
    expect(profile.reload).to be_submitted
  end

  describe "documents" do
    let(:profile) { create(:driver_profile, :complete, user: user) }

    it "are shown to their owner" do
      get document_path(profile.selfie.attachment)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Cache-Control"]).to include("no-store")
    end

    it "are hidden from other users and dispatchers, and shown to admins" do
      attachment = profile.vehicle.registration_document.attachment
      sign_in_as(create(:user))
      get document_path(attachment)
      expect(response).to have_http_status(:not_found)

      sign_in_as(create(:user, :dispatcher))
      get document_path(attachment)
      expect(response).to have_http_status(:not_found)

      sign_in_as(create(:user, :admin))
      get document_path(attachment)
      expect(response).to have_http_status(:ok)
    end
  end
end
