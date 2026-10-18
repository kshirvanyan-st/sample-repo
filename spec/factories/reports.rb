FactoryBot.define do
  factory :report do
    reporter factory: :user
    reported factory: :user
    reason { :spam }
  end
end
