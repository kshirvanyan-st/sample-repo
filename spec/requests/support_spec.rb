require "rails_helper"

RSpec.describe "Support", type: :request do
  include ActiveJob::TestHelper

  let!(:driver) { online_driver(lat: 40.1780, lon: 44.5128) }
  let(:rider) { create(:user) }
  let(:trip) do
    create(:trip, rider: rider, driver_profile: driver, status: :completed, accepted_at: 30.minutes.ago,
      started_at: 20.minutes.ago, completed_at: 5.minutes.ago)
  end

  def texts_to(phone) = SmsSender::TestAdapter.deliveries.select { |sms| sms.to == phone }.map(&:body)

  it "lets a rider report a lost item, tells the driver, and keeps the thread between rider and staff" do
    sign_in_as(rider)
    perform_enqueued_jobs(only: [ DriverLostItemJob, SupportSmsJob ]) do
      post support_tickets_path, params: { kind: "lost_item", trip_id: trip.id, body: "Black umbrella on the back seat" }
    end
    ticket = rider.support_tickets.sole
    expect(response).to redirect_to(support_ticket_path(ticket))
    expect(ticket).to have_attributes(kind: "lost_item", trip: trip, status: "open")
    expect(texts_to(driver.user.phone).last).to include(trip.id.to_s)
    expect(texts_to(driver.user.phone).last).not_to include(rider.phone)

    staff = create(:user, :dispatcher)
    Support.reply!(ticket, author: staff, body: "Internal: called the driver", internal: true)
    perform_enqueued_jobs(only: SupportSmsJob) { Support.reply!(ticket, author: staff, body: "The driver has it.") }
    expect(ticket.reload).to have_attributes(status: "in_progress", assignee: staff)
    expect(texts_to(rider.phone).last).to include(ticket.id.to_s)

    get support_ticket_path(ticket)
    expect(response.body).to include("The driver has it.", "Black umbrella")
    expect(response.body).not_to include("Internal: called the driver")
  end

  it "keeps tickets private and only attaches the user's own trips" do
    other = Support.open!(user: create(:user), kind: :complaint, body: "Not yours")
    sign_in_as(rider)
    get support_ticket_path(other)
    expect(response).to have_http_status(:not_found)

    someone_elses = create(:trip, rider: create(:user))
    post support_tickets_path, params: { kind: "complaint", trip_id: someone_elses.id, body: "Hi" }
    expect(rider.support_tickets.sole.trip).to be_nil
  end

  it "refuses an empty message or a kind users can't pick" do
    sign_in_as(rider)
    post support_tickets_path, params: { kind: "complaint", body: " " }
    expect(response).to have_http_status(:unprocessable_content)
    post support_tickets_path, params: { kind: "sos", body: "fake" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(SupportTicket.count).to eq(0)
  end

  it "reopens a resolved ticket when the user writes again" do
    ticket = Support.open!(user: rider, kind: :fare, body: "Charged twice")
    Support.resolve!(ticket, by: create(:user, :admin))
    sign_in_as(rider)
    post reply_support_ticket_path(ticket), params: { body: "Still wrong" }
    expect(ticket.reload).to be_open
  end

  describe "Admin → Support" do
    let(:dispatcher) { create(:user, :dispatcher) }

    it "is for dispatchers and admins, but other admin pages stay admin-only" do
      sign_in_as(rider)
      get admin_support_tickets_path
      expect(response).to have_http_status(:not_found)

      delete session_path
      sign_in_as(dispatcher)
      get admin_support_tickets_path
      expect(response).to have_http_status(:ok)
      get admin_users_path
      expect(response).to have_http_status(:not_found)
    end

    it "tells open queues to refresh when a ticket comes in" do
      expect { Support.open!(user: rider, kind: :other, body: "Hello") }
        .to have_broadcasted_to("support_queue").from_channel(Turbo::StreamsChannel).with(a_string_including('action="refresh"'))
    end

    it "lists urgent tickets first and works a ticket to resolved" do
      normal = Support.open!(user: rider, kind: :complaint, body: "Rude driver")
      urgent = Support.open!(user: rider, kind: :sos, body: "SOS", priority: :urgent)
      sign_in_as(dispatcher)

      get admin_support_tickets_path
      expect(response.body.index(admin_support_ticket_path(urgent))).to be < response.body.index(admin_support_ticket_path(normal))
      get admin_support_tickets_path(kind: "complaint")
      expect(response.body).not_to include(admin_support_ticket_path(urgent))

      post assign_admin_support_ticket_path(normal)
      expect(normal.reload).to have_attributes(assignee: dispatcher, status: "in_progress")
      post reply_admin_support_ticket_path(normal), params: { body: "Note to self", internal: "1" }
      expect(normal.messages.last).to be_internal
      post resolve_admin_support_ticket_path(normal)
      expect(normal.reload).to be_resolved
      get admin_support_ticket_path(normal)
      expect(response.body).to include("Rude driver", "Note to self")
    end
  end

  describe "drivers needing review" do
    it "shows flagged drivers to admins, who can clear the flag" do
      driver.update!(review_flagged_at: 1.hour.ago, rating_avg: 4.1, rating_count: 20)
      admin = create(:user, :admin)
      sign_in_as(admin)
      get admin_driver_applications_path(status: "review")
      expect(response.body).to include(admin_driver_application_path(driver))
      post reviewed_admin_driver_application_path(driver)
      expect(driver.reload.review_flagged_at).to be_nil
      expect(ModerationAction.where(action: "clear_review", moderator: admin)).to exist
    end
  end
end
