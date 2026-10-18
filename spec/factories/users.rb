FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
  end
end

FactoryBot.modify do
  factory :user do
    transient do
      profile_attributes { {} }
    end

    trait :onboarded do
      after(:create) { |user, ctx| create(:profile, :onboarded, :with_photo, user: user, **ctx.profile_attributes) }
    end
  end
end
