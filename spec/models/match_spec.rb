require "rails_helper"

RSpec.describe Match, type: :model do
  let!(:first) { create(:user) }
  let!(:second) { create(:user) }

  it "stores the pair with the lower id first" do
    match = Match.between!(second, first)
    expect([ match.user_a, match.user_b ]).to eq([ first, second ])
  end

  it "is idempotent" do
    match = Match.between!(first, second)
    expect(Match.between!(second, first)).to eq(match)
    expect(Match.count).to eq(1)
  end

  it "returns the other person" do
    match = Match.between!(first, second)
    expect(match.other(first)).to eq(second)
    expect(match.other(second)).to eq(first)
  end

  it "lists matches for either side" do
    match = Match.between!(first, second)
    expect(first.matches).to eq([ match ])
    expect(second.matches).to eq([ match ])
  end
end
