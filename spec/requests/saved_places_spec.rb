require "rails_helper"

RSpec.describe "Saved places", type: :request do
  let(:user) { create(:user) }

  before { sign_in_as(user) }

  it "adds, edits and deletes a place" do
    post saved_places_path, params: { saved_place: { kind: "home", address: "Tumanyan St 5" } }
    place = user.saved_places.last
    expect(place).to have_attributes(kind: "home", address: "Tumanyan St 5")

    patch saved_place_path(place), params: { saved_place: { address: "Tumanyan St 7" } }
    expect(place.reload.address).to eq("Tumanyan St 7")

    delete saved_place_path(place)
    expect(user.saved_places).to be_empty
  end

  it "puts a saved address on the map" do
    post saved_places_path, params: { saved_place: { kind: "work", address: "Cascade" } }
    expect(user.saved_places.last.location.y).to be_within(0.001).of(40.1913)

    patch saved_place_path(user.saved_places.last), params: { saved_place: { address: "Nowhere at all" } }
    expect(user.saved_places.last.location).to be_nil
  end

  it "can't see or change someone else's places" do
    other = create(:saved_place)
    get edit_saved_place_path(other)
    expect(response).to have_http_status(:not_found)
    delete saved_place_path(other)
    expect(response).to have_http_status(:not_found)
    expect(other.reload).to be_persisted
  end
end
