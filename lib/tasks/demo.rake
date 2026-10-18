namespace :demo do
  desc "Development only: 8 weeks of made-up sign-ups, visits, purchases and gifts so /admin/revenue has something to show"
  task analytics: :environment do
    abort "demo:analytics only runs in development" unless Rails.env.development?

    srand(7)
    packs = CoinPack.available.to_a
    gift = Gift.available.first
    broadcasters = User.joins(:profile).where(email_address: %w[ lilit@example.com ani@example.com mariam@example.com ]).to_a
    photo = Rails.root.join("spec/fixtures/files/photo.jpg")

    55.downto(1) do |days_ago|
      day = days_ago.days.ago
      (3 + rand(6)).times do |i|
        user = User.create!(email_address: "demo-#{days_ago}-#{i}@example.com", password: "password123", created_at: day, updated_at: day)
        next if rand < 0.15 # never finished signing up

        user.create_profile!(display_name: "Member #{days_ago}-#{i}", birthdate: (20 + rand(20)).years.ago, gender: %i[ male female ].sample,
          looking_for: :everyone, onboarded_at: day + 10.minutes, created_at: day, updated_at: day)
        user.profile.photos.create!(image: { io: File.open(photo), filename: "demo.jpg", content_type: "image/jpeg" }, status: :approved)

        # Returning visits that thin out over time.
        [ 1, 2, 3, 7, 14, 30 ].each do |offset|
          break if offset > days_ago
          next unless rand < 0.7 / Math.sqrt(offset)

          Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid, user: user, started_at: day + offset.days)
        end
        Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid, user: user, started_at: day)

        next unless rand < 0.12 # pays

        pack = packs.sample
        paid_at = day + rand(3).days + 2.hours
        next if paid_at > Time.current

        purchase = Purchase.start!(user, pack)
        purchase.fulfill!(payment_intent_id: "pi_demo_#{SecureRandom.hex(4)}")
        purchase.update_columns(created_at: paid_at, paid_at: paid_at, updated_at: paid_at)
        LedgerEntry.where(reference: purchase).update_all(created_at: paid_at)

        stream = Stream.live.find_by(user: broadcasters.sample) || Stream.create!(user: broadcasters.sample, title: "Demo stream", status: :live, started_at: paid_at, viewer_seconds: 3600 * (1 + rand(5)))
        3.times { GiftTransaction.send!(sender: user, stream: stream, gift: gift) rescue nil }
        stream.end!
      end
    end

    Stream.where(title: "Demo stream").update_all(started_at: 20.days.ago)
    Rake::Task["metrics:backfill"].invoke(60)
    puts "Demo analytics data ready: open /admin/revenue"
  end
end
