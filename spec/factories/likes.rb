FactoryBot.define do
  factory :like do
    liker factory: :user
    likee factory: :user
    kind { :like }
  end
end
