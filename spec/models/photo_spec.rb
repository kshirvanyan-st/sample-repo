require "rails_helper"

RSpec.describe Photo, type: :model do
  let(:profile) { create(:profile) }

  def upload(name, type)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files", name), type)
  end

  it "starts pending and is approved by the moderation job" do
    photo = nil
    expect { photo = create(:photo, profile: profile) }.to have_enqueued_job(PhotoModerationJob)
    expect(photo).to be_pending
  end

  it "assigns increasing positions" do
    first = create(:photo, profile: profile)
    second = create(:photo, profile: profile)
    expect([ first.position, second.position ]).to eq([ 0, 1 ])
  end

  it "accepts PNG images" do
    expect(build(:photo, profile: profile, image: upload("photo.png", "image/png"))).to be_valid
  end

  it "requires an image" do
    expect(build(:photo, profile: profile, image: nil)).not_to be_valid
  end

  it "rejects files that aren't images" do
    photo = build(:photo, profile: profile, image: upload("notes.txt", "text/plain"))
    expect(photo).not_to be_valid
    expect(photo.errors[:image]).to include("must be a JPEG, PNG or WebP")
  end

  it "rejects files over 10 MB" do
    photo = build(:photo, profile: profile)
    photo.image.blob.byte_size = 11.megabytes
    expect(photo).not_to be_valid
  end

  it "allows at most 9 photos per profile" do
    create_list(:photo, Photo::MAX_PER_PROFILE, profile: profile)
    photo = build(:photo, profile: profile)
    expect(photo).not_to be_valid
    expect(photo.errors[:base]).to include("You can upload up to 9 photos")
  end

  describe "#make_main!" do
    it "moves the photo to the front and keeps the others in order" do
      a, b, c = create_list(:photo, 3, :approved, profile: profile)
      c.make_main!
      expect(profile.photos.reload).to eq([ c, a, b ])
    end
  end
end
