require "rails_helper"

RSpec.describe Settlement do
  include ActiveJob::TestHelper

  let!(:driver) { online_driver(lat: 40.1780, lon: 44.5128) }

  def ride(rider = create(:user))
    book(rider).tap { |trip| Dispatch.accept!(trip.offers.sole) }.reload
  end

  def finish(trip)
    TripLifecycle.arrive!(trip, driver)
    TripLifecycle.start!(trip, driver)
    TripLifecycle.complete!(trip, driver)
    trip.reload
  end

  it "takes the commission from the driver's balance when a trip is completed" do
    trip = finish(ride)
    expected = (trip.fare * 0.10).ceil
    expect(trip.commission).to eq(expected)
    expect(driver.reload.balance).to eq(-expected)
    expect(driver.ledger_entries.sole).to have_attributes(kind: "commission", amount: -expected, reference: trip)
  end

  it "rounds the commission up to whole drams, at the configured rate" do
    BusinessSetting.current.update!(commission_percent: 12)
    expect(BusinessSetting.current.commission_on(875)).to eq(105) # 105.0
    expect(BusinessSetting.current.commission_on(871)).to eq(105) # 104.52
  end

  it "charges a trip's commission only once" do
    trip = finish(ride)
    expect { DriverWallet.new(driver).debit!(10, kind: :commission, reference: trip) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "texts the rider a receipt" do
    trip = ride
    TripLifecycle.arrive!(trip, driver)
    TripLifecycle.start!(trip, driver)
    perform_enqueued_jobs(only: TripReceiptJob) { TripLifecycle.complete!(trip, driver) }
    expect(SmsSender::TestAdapter.deliveries.last).to have_attributes(to: trip.rider.phone)
    expect(SmsSender::TestAdapter.deliveries.last.body).to include(trip.fare.to_s)
  end

  describe "late cancellations" do
    let(:rider) { create(:user) }

    it "pays the driver who drove to the pickup, and adds the fee to the rider's next trip" do
      trip = ride(rider)
      travel 3.minutes do
        TripLifecycle.cancel!(trip, by: rider)
      end
      expect(driver.reload.balance).to eq(300)
      expect(rider.reload.outstanding_fee).to eq(300)

      quote = quote_for(rider)
      second = Dispatch.request!(quote: quote, vehicle_class: "economy")
      expect(second).to have_attributes(fare: quote.prices["economy"] + 300, outstanding_fee: 300)

      Dispatch.accept!(second.offers.sole)
      finish(second)
      expect(rider.reload.outstanding_fee).to eq(0)
      commission = (quote.prices["economy"] * 0.10).ceil
      # +300 payout, then the driver hands the 300 collected in cash on to the platform and pays commission on the ride itself
      expect(driver.reload.balance).to eq(300 - 300 - commission)
      expect(driver.ledger_entries.pluck(:kind)).to contain_exactly("cancellation_payout", "fee_collection", "commission")
    end

    it "costs nothing within the free minutes" do
      trip = ride(rider)
      TripLifecycle.cancel!(trip, by: rider)
      expect(driver.reload.balance).to eq(0)
      expect(rider.reload.outstanding_fee).to eq(0)
    end
  end

  describe "going online" do
    it "needs the balance at or above the minimum" do
      driver.go_offline!
      DriverWallet.new(driver).debit!(2001, kind: :adjustment, note: "test")
      expect { driver.reload.go_online! }.to raise_error(Dispatch::Error, "low_balance")
      expect(Settlement.needed_to_go_online(driver)).to eq(1)

      DriverWallet.new(driver).credit!(1, kind: :adjustment, note: "test")
      expect { driver.reload.go_online! }.not_to raise_error
    end

    it "keeps dispatch away from drivers below the minimum" do
      DriverWallet.new(driver).debit!(5000, kind: :adjustment, note: "test")
      expect(book.offers).to be_empty
    end
  end
end
