require "rails_helper"

RSpec.describe PhotoModerationJob, type: :job do
  it "approves pending photos" do
    photo = create(:photo)
    described_class.perform_now(photo)
    expect(photo.reload).to be_approved
  end

  it "leaves rejected photos alone" do
    photo = create(:photo, status: :rejected)
    described_class.perform_now(photo)
    expect(photo.reload).to be_rejected
  end
end
