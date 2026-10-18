require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to have_many(:sessions).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:email_address) }
  it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
  it { is_expected.to validate_length_of(:password).is_at_least(8) }

  it "normalizes the email address" do
    expect(build(:user, email_address: "  Ann@Example.COM ").email_address).to eq("ann@example.com")
  end

  it "rejects malformed email addresses" do
    expect(build(:user, email_address: "not-an-email")).not_to be_valid
  end
end
