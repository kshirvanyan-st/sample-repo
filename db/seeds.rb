# `bin/rails db:seed` (idempotent). The coin pack and gift catalog is needed in every
# environment; run it once in production with `bin/kamal app exec "bin/rails db:seed"`.

[
  { name: "Starter", coins: 100, bonus_coins: 0, price_cents: 99, position: 1 },
  { name: "Popular", coins: 500, bonus_coins: 50, price_cents: 499, position: 2 },
  { name: "Best value", coins: 1200, bonus_coins: 200, price_cents: 999, position: 3 },
  { name: "Mega", coins: 2600, bonus_coins: 600, price_cents: 1999, position: 4 }
].each { |attrs| CoinPack.find_or_create_by!(name: attrs[:name]) { |pack| pack.assign_attributes(attrs) } }

[
  { name: "Rose", emoji: "🌹", coins: 5, position: 1 },
  { name: "Coffee", emoji: "☕", coins: 10, position: 2 },
  { name: "Heart", emoji: "💖", coins: 25, position: 3 },
  { name: "Teddy", emoji: "🧸", coins: 50, position: 4 },
  { name: "Diamond", emoji: "💎", coins: 100, position: 5 },
  { name: "Rocket", emoji: "🚀", coins: 500, position: 6 }
].each { |attrs| Gift.find_or_create_by!(name: attrs[:name]) { |gift| gift.assign_attributes(attrs) } }

# Everything below is demo data for trying the app locally.
return unless Rails.env.development?

require "vips"

NAMES = {
  "female" => %w[ Ani Mariam Lilit Nare Sona Anahit Elen Gayane Tatev Lusine Karine Milena ],
  "male" => %w[ Aram Davit Tigran Narek Arman Hayk Gor Levon Samvel Erik Vahe Artur ],
  "other" => %w[ Alex Sasha Robin ]
}.freeze
CITY_CENTER = [ 40.1792, 44.4991 ].freeze # Yerevan
COLORS = [ [ 236, 72, 153 ], [ 59, 130, 246 ], [ 16, 185, 129 ], [ 245, 158, 11 ], [ 139, 92, 246 ] ].freeze

def seed_photo(profile, index)
  return if profile.photos.exists?

  rgb = COLORS[index % COLORS.size]
  image = Vips::Image.black(600, 800).new_from_image(rgb).cast(:uchar)
  blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(image.jpegsave_buffer), filename: "seed-#{index}.jpg", content_type: "image/jpeg")
  profile.photos.create!(image: blob, status: :approved)
end

def seed_user(email:, name:, gender:, looking_for:, age:, index:)
  user = User.find_or_create_by!(email_address: email) { |u| u.password = "password123" }
  profile = user.profile || user.build_profile
  profile.update!(
    display_name: name, gender: gender, looking_for: looking_for,
    birthdate: age.years.ago.to_date - index.days, city: "Yerevan",
    bio: "Hi, I'm #{name}! Coffee, mountains and good music.",
    latitude: CITY_CENTER[0] + rand(-0.15..0.15), longitude: CITY_CENTER[1] + rand(-0.15..0.15),
    onboarded_at: profile.onboarded_at || Time.current
  )
  seed_photo(profile, index)
  user
end

srand(42)
demo = seed_user(email: "demo@example.com", name: "Demo", gender: "male", looking_for: "women", age: 28, index: 0)

index = 1
NAMES.each do |gender, names|
  names.each do |name|
    looking_for = gender == "female" ? %w[ men men everyone ].sample : %w[ women women everyone ].sample
    seed_user(email: "#{name.downcase}@example.com", name: name, gender: gender, looking_for: looking_for, age: rand(20..40), index: index)
    index += 1
  end
end

# A few people already like the demo user, so "Liked me" and matching can be tried right away.
User.where(email_address: %w[ ani@example.com mariam@example.com lilit@example.com ]).find_each do |user|
  user.likes_given.find_or_create_by!(likee: demo) { |like| like.kind = :like }
end

# A match with a short chat so the Chats page has something in it.
ani = User.find_by!(email_address: "ani@example.com")
demo.likes_given.find_or_create_by!(likee: ani) { |like| like.kind = :like }
conversation = Conversation.open_for!(Match.between!(demo, ani))
if conversation.messages.none?
  [ [ ani, "Hi! I saw you like the mountains too 🏔️" ], [ demo, "Hey Ani! Yes, Aragats last weekend." ], [ ani, "Nice, which trail?" ] ].each do |sender, body|
    conversation.messages.create!(sender: sender, body: body)
  end
end

# Some coins so gifts can be tried without a payment.
User.where(email_address: %w[ demo@example.com ani@example.com lilit@example.com ]).find_each do |user|
  Wallet.new(user).credit!(300, kind: :adjustment) if user.ledger_entries.none?
end

puts "Seeded #{Profile.count} profiles. Sign in as demo@example.com / password123."
