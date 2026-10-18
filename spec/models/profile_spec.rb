require "rails_helper"

RSpec.describe Profile, type: :model do
  subject(:profile) { build(:profile) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:photos).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:display_name) }
  it { is_expected.to validate_presence_of(:birthdate) }
  it { is_expected.to validate_length_of(:bio).is_at_most(500) }
  it { is_expected.to validate_numericality_of(:latitude).is_in(-90..90).allow_nil }
  it { is_expected.to validate_numericality_of(:longitude).is_in(-180..180).allow_nil }

  describe "age requirement" do
    it "accepts someone who turns 18 today" do
      profile.birthdate = 18.years.ago.to_date
      expect(profile).to be_valid
    end

    it "rejects someone under 18" do
      profile.birthdate = 18.years.ago.to_date + 1.day
      expect(profile).not_to be_valid
      expect(profile.errors[:birthdate]).to include("shows you are under 18")
    end
  end

  describe "#age" do
    it "counts full years only" do
      profile.birthdate = Date.new(2000, 6, 15)
      expect(profile.age(on: Date.new(2026, 6, 14))).to eq(25)
      expect(profile.age(on: Date.new(2026, 6, 15))).to eq(26)
    end
  end

  describe "photos" do
    let(:profile) { create(:profile) }

    it "returns the first approved photo as the main photo" do
      create(:photo, profile: profile)
      approved = create(:photo, :approved, profile: profile)
      expect(profile.main_photo).to eq(approved)
    end

    it "shows pending photos only to the owner" do
      pending_photo = create(:photo, profile: profile)
      expect(profile.visible_photos_for(profile.user)).to include(pending_photo)
      expect(profile.visible_photos_for(create(:user))).not_to include(pending_photo)
    end
  end
end
