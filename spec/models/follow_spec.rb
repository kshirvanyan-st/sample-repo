require "rails_helper"

RSpec.describe Follow, type: :model do
  subject { create(:follow) }

  it { is_expected.to validate_uniqueness_of(:followee_id).scoped_to(:follower_id) }

  it "can't follow yourself" do
    user = create(:user)
    follow = build(:follow, follower: user, followee: user)
    expect(follow).not_to be_valid
    expect(follow.errors[:followee]).to include("can't be yourself")
  end

  it "connects followers and following" do
    alice, bob = create_list(:user, 2)
    alice.follow(bob)
    expect(alice.following).to eq([ bob ])
    expect(bob.followers).to eq([ alice ])
    expect(alice.following?(bob)).to be(true)

    alice.unfollow(bob)
    expect(alice.following?(bob)).to be(false)
  end
end
