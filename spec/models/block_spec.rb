require "rails_helper"

RSpec.describe Block, type: :model do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }

  subject { create(:block) }

  it { is_expected.to validate_uniqueness_of(:blocked_id).scoped_to(:blocker_id) }

  it "can't block yourself" do
    expect(build(:block, blocker: alice, blocked: alice)).not_to be_valid
  end

  it "removes the match and follows in both directions" do
    Match.between!(alice, bob)
    alice.follow(bob)
    bob.follow(alice)

    create(:block, blocker: bob, blocked: alice)

    expect(alice.matched_with?(bob)).to be(false)
    expect(Follow.count).to eq(0)
    expect(alice.blocked_user_ids).to eq([ bob.id ])
    expect(bob.blocked_user_ids).to eq([ alice.id ])
    expect(alice.blocked_with?(bob)).to be(true)
  end
end
