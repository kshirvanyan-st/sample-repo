FactoryBot.define do
  factory :message do
    conversation
    sender { conversation.match.user_a }
    sequence(:body) { |n| "Message #{n}" }
  end
end
