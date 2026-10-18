require "rails_helper"

RSpec.describe Like, type: :model do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }

  subject { create(:like) }

  it { is_expected.to validate_uniqueness_of(:likee_id).scoped_to(:liker_id) }

  it "can't like yourself" do
    expect(build(:like, liker: alice, likee: alice)).not_to be_valid
  end

  it "creates a match when the like is mutual" do
    create(:like, liker: alice, likee: bob)
    expect { create(:like, liker: bob, likee: alice) }.to change(Match, :count).by(1)
    expect(alice.matched_with?(bob)).to be(true)
  end

  it "counts super likes as positive" do
    create(:like, liker: alice, likee: bob, kind: :superlike)
    expect { create(:like, liker: bob, likee: alice) }.to change(Match, :count).by(1)
  end

  it "doesn't match on a one-sided like" do
    expect { create(:like, liker: alice, likee: bob) }.not_to change(Match, :count)
  end

  it "doesn't match when either side skipped" do
    create(:like, liker: alice, likee: bob, kind: :skip)
    expect { create(:like, liker: bob, likee: alice) }.not_to change(Match, :count)
  end

  it "doesn't create a second match if one already exists" do
    Match.between!(alice, bob)
    create(:like, liker: alice, likee: bob)
    expect { create(:like, liker: bob, likee: alice) }.not_to change(Match, :count)
  end
end
