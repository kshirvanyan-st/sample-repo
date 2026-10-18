require "rails_helper"

RSpec.describe "Photos", type: :request do
  let(:user) { create(:user, :onboarded) }
  let(:profile) { user.profile }

  before { sign_in_as(user) }

  it "uploads a photo" do
    expect {
      post photos_path, params: { photo: { image: fixture_file_upload("photo.png", "image/png") } }
    }.to change(profile.photos, :count).by(1)
    expect(response).to redirect_to(photos_path)
  end

  it "rejects invalid uploads" do
    expect {
      post photos_path, params: { photo: { image: fixture_file_upload("notes.txt", "text/plain") } }
    }.not_to change(Photo, :count)
    expect(flash[:alert]).to include("must be a JPEG, PNG or WebP")
  end

  it "deletes a photo but keeps at least one" do
    extra = create(:photo, :approved, profile: profile)
    delete photo_path(extra)
    expect(Photo.exists?(extra.id)).to be(false)

    delete photo_path(profile.photos.first)
    expect(profile.photos.count).to eq(1)
    expect(flash[:alert]).to eq("Your profile needs at least one photo.")
  end

  it "makes a photo the main one" do
    extra = create(:photo, :approved, profile: profile)
    patch make_main_photo_path(extra)
    expect(profile.photos.reload.first).to eq(extra)
  end

  it "can't touch someone else's photos" do
    other_photo = create(:user, :onboarded).profile.photos.first
    delete photo_path(other_photo)
    expect(response).to have_http_status(:not_found)
    expect(Photo.exists?(other_photo.id)).to be(true)
  end
end
