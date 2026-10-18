FactoryBot.define do
  factory :profile do
    user
    sequence(:display_name) { |n| "Person #{n}" }
    birthdate { 25.years.ago.to_date }
    gender { :female }
    looking_for { :everyone }
    city { "Yerevan" }

    trait :onboarded do
      onboarded_at { Time.current }
    end

    trait :with_photo do
      after(:create) { |profile| create(:photo, :approved, profile: profile) }
    end
  end
end
