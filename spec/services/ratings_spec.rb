require "rails_helper"

RSpec.describe Ratings do
  include ActiveJob::TestHelper

  let!(:driver) { online_driver(lat: 40.1780, lon: 44.5128) }

  def completed_trip(rider = create(:user))
    create(:trip, rider: rider, driver_profile: driver, status: :completed, accepted_at: 30.minutes.ago,
      started_at: 20.minutes.ago, completed_at: 5.minutes.ago)
  end

  it "lets each side rate once, and keeps the averages" do
    trip = completed_trip
    Ratings.submit!(trip: trip, rater: trip.rider, stars: 4, reasons: [ "friendly" ])
    Ratings.submit!(trip: trip, rater: driver.user, stars: 5)
    expect(driver.reload).to have_attributes(rating_avg: 4, rating_count: 1)
    expect(trip.rider.reload).to have_attributes(rider_rating_avg: 5, rider_rating_count: 1)
    expect { Ratings.submit!(trip: trip, rater: trip.rider, stars: 5) }.to raise_error(Ratings::Error, "already_rated")
    expect(Ratings.pending?(trip, trip.rider)).to be(false)
  end

  it "is only for the trip's people, after it's done, within a week" do
    trip = book
    Dispatch.accept!(trip.offers.sole)
    expect { Ratings.submit!(trip: trip.reload, rater: trip.rider, stars: 5) }.to raise_error(Ratings::Error, "too_late")

    done = completed_trip
    expect { Ratings.submit!(trip: done, rater: create(:user), stars: 5) }.to raise_error(Ratings::Error, "not_allowed")
    expect { Ratings.submit!(trip: done, rater: done.rider, stars: 6) }.to raise_error(Ratings::Error, "bad_rating")
    expect { Ratings.submit!(trip: done, rater: done.rider, stars: 2, reasons: [ "made_up" ]) }.to raise_error(Ratings::Error, "bad_rating")
    travel 8.days do
      expect(Ratings.pending?(done, done.rider)).to be(false)
      expect { Ratings.submit!(trip: done, rater: done.rider, stars: 5) }.to raise_error(Ratings::Error, "too_late")
    end
  end

  it "averages only the most recent ratings and flags low drivers for review, once" do
    rider = create(:user)
    trip = completed_trip(rider)
    Ratings.submit!(trip: trip, rater: rider, stars: 1)
    # Older ratings outside the window don't count.
    users = create_list(:user, Ratings::WINDOW)
    users.each { |user| Ratings.submit!(trip: completed_trip(user), rater: user, stars: 5) }
    expect(driver.reload.rating_avg).to eq(5)
    expect(driver.rating_count).to eq(Ratings::WINDOW + 1)
    expect(driver.review_flagged_at).to be_nil

    create_list(:user, 10).each { |user| Ratings.submit!(trip: completed_trip(user), rater: user, stars: 3) }
    expect(driver.reload.rating_avg).to be < Ratings::REVIEW_BELOW
    expect(driver.review_flagged_at).to be_present
    expect(ModerationAction.where(action: "flag_for_review", user: driver.user).count).to eq(1)
  end

  it "doesn't flag a driver with only a few ratings" do
    rider = create(:user)
    Ratings.submit!(trip: completed_trip(rider), rater: rider, stars: 1)
    expect(driver.reload.review_flagged_at).to be_nil
  end

  it "opens a safety ticket for a one-star unsafe-driving rating" do
    trip = completed_trip
    Ratings.submit!(trip: trip, rater: trip.rider, stars: 1, reasons: [ "unsafe_driving" ], comment: "Ran red lights")
    ticket = SupportTicket.sole
    expect(ticket).to have_attributes(kind: "safety", trip: trip, user: trip.rider, priority: "normal")
    expect(ticket.messages.sole.body).to eq("Ran red lights")
  end

  describe "the dispatch tie-break" do
    it "prefers the higher-rated of drivers arriving at about the same time" do
      good = online_driver
      good.update!(rating_avg: 4.95, rating_count: 50)
      poor = online_driver
      poor.update!(rating_avg: 4.2, rating_count: 50)
      fresh = online_driver

      ranked = Dispatch.rank([ [ poor, 100 ], [ fresh, 120 ], [ good, 150 ] ])
      expect(ranked.map(&:first)).to eq([ good, fresh, poor ])
    end

    it "still sends the clearly closer driver" do
      good = online_driver
      good.update!(rating_avg: 5, rating_count: 50)
      poor = online_driver
      poor.update!(rating_avg: 4.0, rating_count: 50)
      expect(Dispatch.rank([ [ poor, 60 ], [ good, 400 ] ]).map(&:first)).to eq([ poor, good ])
    end
  end
end
