FactoryBot.define do
  factory :block do
    blocker factory: :user
    blocked factory: :user
  end
end
