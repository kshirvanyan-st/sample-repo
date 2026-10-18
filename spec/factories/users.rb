FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
  end
end

FactoryBot.modify do
  factory :user do
    trait :onboarded do
      after(:create) { |user| create(:profile, :onboarded, :with_photo, user: user) }
    end
  end
end
