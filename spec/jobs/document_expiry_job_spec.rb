require "rails_helper"

RSpec.describe DocumentExpiryJob, type: :job do
  include ActiveJob::TestHelper

  let(:today) { Date.new(2026, 10, 18) }
  let(:profile) { create(:driver_profile, :approved, license_expires_on: today + 20) }

  before { profile.user.update!(locale: "en") }

  it "texts a reminder 30 days ahead, once" do
    described_class.perform_now(today)
    described_class.perform_now(today + 1)
    expect(SmsSender::TestAdapter.deliveries.map(&:body)).to eq([ "Taxi AM: your driver's license expires on November 07, 2026. Renew it in time to keep driving." ])
  end

  it "texts again 7 days ahead" do
    described_class.perform_now(today)
    described_class.perform_now(today + 14)
    expect(SmsSender::TestAdapter.deliveries.size).to eq(2)
    expect(ExpiryNotice.pluck(:stage)).to eq(%w[ 30_days 7_days ])
  end

  it "suspends the driver once a document has expired" do
    profile.vehicle.update!(insurance_expires_on: today - 1)
    perform_enqueued_jobs { described_class.perform_now(today) }
    expect(profile.reload).to be_suspended
    expect(profile.review_note).to include("car insurance")
    expect(ModerationAction.last).to have_attributes(moderator: nil, action: "suspend_driver")
    expect(SmsSender::TestAdapter.deliveries.last.body).to include("suspended")
  end

  it "leaves drivers who aren't approved alone" do
    create(:driver_profile, :submitted, license_expires_on: today + 3)
    expect { described_class.perform_now(today) }.to change(ExpiryNotice, :count).by(1) # only the approved driver's
  end
end
