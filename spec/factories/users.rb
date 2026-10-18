FactoryBot.define do
  factory :user do
    sequence(:phone) { |n| "+3749#{(1_000_000 + n).to_s[-7..]}" }
    name { "Anna" }

    trait(:driver) { role { :driver } }
    trait(:dispatcher) { role { :dispatcher } }
    trait(:admin) { role { :admin } }
    trait(:banned) { banned_at { 1.day.ago } }
  end

  factory :saved_place do
    user
    kind { :other }
    address { "Abovyan St 1, Yerevan" }
  end
end
