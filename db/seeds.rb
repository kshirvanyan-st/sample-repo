# Demo data for trying the swipe deck locally: `bin/rails db:seed`.
# Idempotent; does nothing outside development.
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

puts "Seeded #{Profile.count} profiles. Sign in as demo@example.com / password123."
