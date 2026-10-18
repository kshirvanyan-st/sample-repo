require "rails_helper"

RSpec.describe "Safety", type: :request do
  include ActiveJob::TestHelper

  let!(:driver) { online_driver(lat: 40.1780, lon: 44.5128) }
  let(:rider) { create(:user, name: "Anna Petrosyan") }
  let(:trip) { book(rider).tap { |trip| Dispatch.accept!(trip.offers.sole) }.reload }

  def texts_to(phone) = SmsSender::TestAdapter.deliveries.select { |sms| sms.to == phone }.map(&:body)

  describe "sharing a trip" do
    it "gives the rider a link that shows the car, driver and plate, and nothing private" do
      sign_in_as(rider)
      post trip_share_link_path(trip)
      url = response.parsed_body["url"]
      expect(url).to match(%r{/t/\w{32}\z})
      expect(response.parsed_body["text"]).to include("Anna")

      delete session_path
      get URI(url).path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(driver.vehicle.plate_number, driver.user.name.split.first)
      expect(response.body).not_to include(rider.phone, rider.name, ActiveSupport::NumberHelper.number_to_delimited(trip.fare))
    end

    it "is only for the trip's rider" do
      sign_in_as(create(:user))
      post trip_share_link_path(trip)
      expect(response).to have_http_status(:not_found)
    end

    it "expires an hour after the trip ends" do
      link = ShareLink.for(trip)
      TripLifecycle.cancel!(trip, by: rider)
      get shared_trip_path(link.token)
      expect(response).to have_http_status(:ok)
      travel ShareLink::AFTER_END + 1.minute do
        get shared_trip_path(link.token)
        expect(response).to have_http_status(:not_found)
      end
      get shared_trip_path("nope")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "SOS" do
    let!(:staff) { [ create(:user, :admin), create(:user, :dispatcher) ] }

    before do
      rider.emergency_contacts.create!(name: "Mom", phone: "094 111 222")
      sign_in_as(rider)
    end

    it "opens an urgent ticket where the rider is and texts their contacts and staff" do
      trip # booked before running jobs, so the offer timeout doesn't fire
      perform_enqueued_jobs(only: SupportSmsJob) do
        post trip_sos_path(trip), params: { lat: 40.1801, lon: 44.5133 }
      end
      expect(response).to redirect_to(trip_path(trip))
      ticket = SupportTicket.sole
      expect(ticket).to have_attributes(kind: "sos", priority: "urgent", trip: trip, user: rider)
      expect([ ticket.location.y, ticket.location.x ]).to eq([ 40.1801, 44.5133 ])

      link = "http://localhost:3000/t/#{trip.share_link.token}"
      expect(texts_to("+37494111222").sole).to include("Anna", link)
      staff.each { |user| expect(texts_to(user.phone).last).to include(ticket.id.to_s, "/t/") }
    end

    it "uses the car's position when the phone can't tell" do
      post trip_sos_path(trip)
      expect(SupportTicket.sole.location).to eq(driver.location.location)
    end

    it "is only for an active trip" do
      TripLifecycle.cancel!(trip, by: rider)
      post trip_sos_path(trip)
      expect(response).to redirect_to(trip_path(trip))
      expect(SupportTicket.count).to eq(0)
    end
  end

  describe "emergency contacts" do
    before { sign_in_as(rider) }

    it "adds up to three and removes them" do
      3.times { |i| post emergency_contacts_path, params: { emergency_contact: { name: "C#{i}", phone: "094 00 00 0#{i}" } } }
      expect(rider.emergency_contacts.pluck(:phone)).to all(start_with("+374"))
      post emergency_contacts_path, params: { emergency_contact: { name: "Four", phone: "094 000 004" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(rider.emergency_contacts.count).to eq(3)

      delete emergency_contact_path(rider.emergency_contacts.first)
      expect(rider.emergency_contacts.count).to eq(2)
    end

    it "rejects a bad number and keeps others' contacts private" do
      post emergency_contacts_path, params: { emergency_contact: { name: "X", phone: "12" } }
      expect(response).to have_http_status(:unprocessable_content)
      other = create(:user).emergency_contacts.create!(name: "Y", phone: "094 222 333")
      delete emergency_contact_path(other)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "rating on the trip page" do
    it "asks the rider to rate a finished trip" do
      [ :arrive!, :start!, :complete! ].each { |step| TripLifecycle.public_send(step, trip, driver) }
      sign_in_as(rider)
      get trip_path(trip)
      expect(response.body).to include(trip_rating_path(trip))
      post trip_rating_path(trip), params: { stars: 5, reasons: [ "friendly" ] }
      expect(driver.reload.rating_avg).to eq(5)
      follow_redirect!
      expect(response.body).not_to include(trip_rating_path(trip))
    end
  end
end
