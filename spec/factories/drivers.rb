FactoryBot.define do
  factory :driver_profile do
    user

    # Everything needed to submit: license, documents and a valid car.
    trait :complete do
      license_number { "AB123456" }
      license_expires_on { 2.years.from_now.to_date }
      after(:build) do |profile|
        DriverProfile::DOCUMENTS.each { |name| profile.public_send(name).attach(Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/document.png"), "image/png")) }
        profile.vehicle ||= build(:vehicle, :complete, driver_profile: profile)
      end
    end

    trait :submitted do
      complete
      status { :submitted }
      submitted_at { 1.hour.ago }
    end

    trait :approved do
      complete
      status { :approved }
      submitted_at { 2.days.ago }
      approved_at { 1.day.ago }
      after(:create) { |profile| profile.user.update!(role: :driver) }
    end
  end

  factory :vehicle do
    driver_profile

    trait :complete do
      make { "Toyota" }
      model { "Camry" }
      color { "White" }
      year { Date.current.year - 3 }
      sequence(:plate_number) { |n| format("%02d OS %03d", 10 + n / 1000 % 90, n % 1000) }
      registration_expires_on { 1.year.from_now.to_date }
      insurance_expires_on { 1.year.from_now.to_date }
      after(:build) do |vehicle|
        Vehicle::DOCUMENTS.each { |name| vehicle.public_send(name).attach(Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/document.png"), "image/png")) }
      end
    end
  end
end
