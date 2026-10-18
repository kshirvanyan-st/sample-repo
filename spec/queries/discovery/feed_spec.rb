require "rails_helper"

RSpec.describe Discovery::Feed do
  YEREVAN = { latitude: 40.1792, longitude: 44.4991 }.freeze
  GYUMRI = { latitude: 40.7894, longitude: 43.8475 }.freeze # ~90 km away

  def person(gender:, looking_for:, age: 30, **attrs)
    create(:user, :onboarded, profile_attributes: { gender: gender, looking_for: looking_for, birthdate: age.years.ago.to_date - 1.day, **attrs }).profile
  end

  let(:viewer) { person(gender: :male, looking_for: :women).user }
  let(:feed) { described_class.new(viewer) }

  it "matches gender preferences in both directions" do
    into_men = person(gender: :female, looking_for: :men)
    into_everyone = person(gender: :female, looking_for: :everyone)
    into_women = person(gender: :female, looking_for: :women)
    man = person(gender: :male, looking_for: :women)
    other = person(gender: :other, looking_for: :everyone)

    expect(feed.candidates).to contain_exactly(into_men, into_everyone)
    expect(feed.candidates).not_to include(into_women, man, other)
  end

  it "shows every gender to people looking for everyone" do
    viewer.profile.update!(looking_for: :everyone)
    other = person(gender: :other, looking_for: :everyone)
    man = person(gender: :male, looking_for: :men)
    expect(feed.candidates).to include(other, man)
  end

  it "respects the age range, inclusive" do
    viewer.profile.update!(age_min: 25, age_max: 30)
    youngest = person(gender: :female, looking_for: :men, age: 25)
    oldest = person(gender: :female, looking_for: :men, age: 30)
    too_young = person(gender: :female, looking_for: :men, age: 24)
    too_old = person(gender: :female, looking_for: :men, age: 31)

    expect(feed.candidates).to include(youngest, oldest)
    expect(feed.candidates).not_to include(too_young, too_old)
  end

  it "excludes people already rated, blocked either way, unfinished or without approved photos" do
    rated = person(gender: :female, looking_for: :men)
    skipped = person(gender: :female, looking_for: :men)
    blocked = person(gender: :female, looking_for: :men)
    blocker = person(gender: :female, looking_for: :men)
    unfinished = create(:profile, gender: :female, looking_for: :men)
    pending_only = create(:profile, :onboarded, gender: :female, looking_for: :men)
    create(:photo, profile: pending_only)
    visible = person(gender: :female, looking_for: :men)

    create(:like, liker: viewer, likee: rated.user)
    create(:like, liker: viewer, likee: skipped.user, kind: :skip)
    create(:block, blocker: viewer, blocked: blocked.user)
    create(:block, blocker: blocker.user, blocked: viewer)

    expect(feed.candidates).to contain_exactly(visible)
    expect(feed.candidates).not_to include(unfinished)
  end

  context "when the viewer has a location" do
    before { viewer.profile.update!(**YEREVAN, max_distance_km: 50) }

    it "keeps people within range, nearest first, and reports the distance" do
      far_in_city = person(gender: :female, looking_for: :men, latitude: 40.30, longitude: 44.60)
      near = person(gender: :female, looking_for: :men, latitude: 40.18, longitude: 44.50)
      far_away = person(gender: :female, looking_for: :men, **GYUMRI)
      no_location = person(gender: :female, looking_for: :men)

      expect(feed.candidates.to_a).to eq([ near, far_in_city ])
      expect(feed.next_profile.distance_km.to_f).to be < 1
      expect(feed.candidates).not_to include(far_away, no_location)
    end

    it "includes everyone with a location when the distance is unlimited" do
      viewer.profile.update!(max_distance_km: nil)
      far_away = person(gender: :female, looking_for: :men, **GYUMRI)
      expect(feed.candidates).to include(far_away)
    end
  end

  it "doesn't filter by distance when the viewer has no location" do
    far_away = person(gender: :female, looking_for: :men, **GYUMRI)
    no_location = person(gender: :female, looking_for: :men)
    expect(feed.candidates).to include(far_away, no_location)
  end
end
