require "rails_helper"

RSpec.describe DriverProfile, type: :model do
  def upload(name = "document.png", type = "image/png")
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files", name), type)
  end

  it "saves an empty draft" do
    expect(create(:driver_profile)).to be_draft
  end

  it "submits a complete application" do
    profile = create(:driver_profile, :complete)
    profile.submit!
    expect(profile.reload).to be_submitted
    expect(profile.submitted_at).to be_present
  end

  it "won't submit without documents, license details or a car" do
    profile = create(:driver_profile)
    expect { profile.submit! }.to raise_error(ActiveRecord::RecordInvalid)
    expect(profile.errors.attribute_names).to include(:license_number, :license_expires_on, :vehicle, *DriverProfile::DOCUMENTS)
  end

  it "won't submit an expired license" do
    profile = create(:driver_profile, :complete, license_expires_on: Date.yesterday)
    expect { profile.submit! }.to raise_error(ActiveRecord::RecordInvalid)
    expect(profile.errors).to be_added(:license_expires_on, :expired)
  end

  it "checks the car on submit" do
    profile = create(:driver_profile, :complete)
    profile.vehicle.update!(insurance_expires_on: Date.yesterday)
    expect { profile.submit! }.to raise_error(ActiveRecord::RecordInvalid)
    expect(profile.vehicle.errors).to be_added(:insurance_expires_on, :expired)
  end

  it "accepts photos and PDFs but not other files" do
    profile = create(:driver_profile)
    profile.update(license_front: upload("document.pdf", "application/pdf"))
    expect(profile).to be_valid

    profile.update(license_back: upload("script.html", "image/png")) # the declared type is ignored
    expect(profile.errors).to be_added(:license_back, :document_type)
  end

  it "rejects files over the size limit" do
    profile = create(:driver_profile)
    stub_const("DocumentAttachments::MAX_SIZE", 10)
    profile.update(selfie: upload)
    expect(profile.errors).to be_added(:selfie, :document_size, max: 0)
  end

  it "is editable only while not under review, approved or rejected" do
    expect(DriverProfile.statuses.keys.select { |status| DriverProfile.new(status: status).editable? }).to eq(%w[ draft needs_changes suspended ])
  end
end
