require "rails_helper"

RSpec.describe SavedPlace, type: :model do
  let(:user) { create(:user) }

  it { is_expected.to validate_presence_of(:address) }

  it "allows one home and one work place per user, and any number of others" do
    create(:saved_place, user: user, kind: :home)
    expect(build(:saved_place, user: user, kind: :home)).not_to be_valid
    expect(build(:saved_place, user: create(:user), kind: :home)).to be_valid

    create(:saved_place, user: user, kind: :other)
    expect(build(:saved_place, user: user, kind: :other)).to be_valid
  end

  it "stores a geography point" do
    place = create(:saved_place, location: "POINT(44.5152 40.1772)")
    expect(place.reload.location.latitude).to be_within(0.0001).of(40.1772)
  end

  it "titles home and work by kind, others by label" do
    I18n.with_locale(:en) do
      expect(build(:saved_place, kind: :home).title).to eq("Home")
      expect(build(:saved_place, kind: :other, label: "Gym").title).to eq("Gym")
    end
  end
end
