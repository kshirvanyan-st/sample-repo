FactoryBot.define do
  factory :coin_pack do
    sequence(:name) { |n| "Pack #{n}" }
    coins { 500 }
    bonus_coins { 50 }
    price_cents { 499 }
    currency { "usd" }
  end

  factory :purchase do
    user
    coin_pack
    coins { coin_pack.total_coins }
    amount_cents { coin_pack.price_cents }
    currency { coin_pack.currency }
    sequence(:stripe_checkout_session_id) { |n| "cs_test_#{n}" }
  end

  factory :gift do
    sequence(:name) { |n| "Gift #{n}" }
    emoji { "🌹" }
    coins { 10 }
  end
end
