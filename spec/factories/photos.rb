FactoryBot.define do
  factory :photo do
    profile
    image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/photo.jpg"), "image/jpeg") }

    trait :approved do
      status { :approved }
    end
  end
end
