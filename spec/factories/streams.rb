FactoryBot.define do
  factory :stream do
    user factory: %i[ user onboarded ]
    title { "Evening chat" }
    category { :just_chatting }

    trait :live do
      status { :live }
      started_at { 5.minutes.ago }
    end

    trait :ended do
      status { :ended }
      started_at { 1.hour.ago }
      ended_at { 30.minutes.ago }
    end
  end
end
