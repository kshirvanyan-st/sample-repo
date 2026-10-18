namespace :load do
  desc "Create onboarded users load-1..N@example.com (password: password123) for the k6 scripts in load/"
  task :users, [ :count ] => :environment do |_, args|
    abort "Refusing to create load-test users in production" if Rails.env.production?

    count = Integer(args.fetch(:count, 50))
    photo = Rails.root.join("spec/fixtures/files/photo.jpg")
    count.times do |i|
      user = User.find_or_create_by!(email_address: "load-#{i + 1}@example.com") { |u| u.password = "password123" }
      next if user.onboarded?

      profile = user.create_profile!(display_name: "Load #{i + 1}", birthdate: (20 + i % 20).years.ago, gender: i.even? ? :female : :male,
        looking_for: :everyone, city: "Yerevan", latitude: 40.18 + rand * 0.1, longitude: 44.5 + rand * 0.1, onboarded_at: Time.current)
      profile.photos.create!(image: { io: File.open(photo), filename: "load.jpg", content_type: "image/jpeg" }, status: :approved)
    end
    puts "#{count} load-test users ready (load-1..#{count}@example.com / password123)."
  end
end
