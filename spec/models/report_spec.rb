require "rails_helper"

RSpec.describe Report, type: :model do
  it { is_expected.to validate_length_of(:details).is_at_most(1000) }

  it "starts open" do
    expect(create(:report)).to be_open
  end

  it "can't report yourself" do
    user = create(:user)
    expect(build(:report, reporter: user, reported: user)).not_to be_valid
  end
end
