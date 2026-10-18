FactoryBot.define do
  factory :match do
    transient do
      users { create_list(:user, 2).sort_by(&:id) }
    end

    user_a { users.first }
    user_b { users.last }
  end
end
