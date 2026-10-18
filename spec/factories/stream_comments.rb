FactoryBot.define do
  factory :stream_comment do
    stream factory: %i[ stream live ]
    user factory: %i[ user onboarded ]
    body { "Hi!" }
  end
end
