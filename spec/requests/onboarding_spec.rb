require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) { create(:user) }
  let(:photo) { fixture_file_upload("photo.jpg", "image/jpeg") }

  before { sign_in_as(user) }

  it "sends users without a finished profile to the wizard" do
    get root_path
    expect(response).to redirect_to(onboarding_path("basics"))
  end

  it "rejects unknown steps" do
    get onboarding_path("nope")
    expect(response).to have_http_status(:not_found)
  end

  it "requires the basics step before later steps" do
    get onboarding_path("about")
    expect(response).to redirect_to(onboarding_path("basics"))
  end

  it "walks through every step and finishes onboarding" do
    patch onboarding_path("basics"), params: { profile: { display_name: "Ani", birthdate: "1998-04-02", gender: "female", looking_for: "men" } }
    expect(response).to redirect_to(onboarding_path("about"))

    patch onboarding_path("about"), params: { profile: { city: "Yerevan", bio: "Hiking and jazz", latitude: "40.1792", longitude: "44.4991" } }
    expect(response).to redirect_to(onboarding_path("photos"))

    patch onboarding_path("photos"), params: { profile: { images: [ "", photo ] } }
    expect(response).to redirect_to(root_path)

    profile = user.reload.profile
    expect(profile).to have_attributes(display_name: "Ani", city: "Yerevan", looking_for: "men", latitude: BigDecimal("40.1792"))
    expect(profile.photos.count).to eq(1)
    expect(user).to be_onboarded

    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "rejects under-18 birthdates" do
    patch onboarding_path("basics"), params: { profile: { display_name: "Kid", birthdate: 16.years.ago.to_date, gender: "male", looking_for: "women" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload.profile).to be_nil
  end

  it "requires at least one photo" do
    create(:profile, user: user)
    patch onboarding_path("photos"), params: { profile: { images: [ "" ] } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload).not_to be_onboarded
  end
end
