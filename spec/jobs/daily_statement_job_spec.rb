require "rails_helper"

RSpec.describe DailyStatementJob, type: :job do
  it "texts each driver who drove today, once, in their language" do
    driver = online_driver(lat: 40.1780, lon: 44.5128)
    driver.user.update!(locale: "ru")
    trip = book.tap { |t| Dispatch.accept!(t.offers.sole) }.reload
    TripLifecycle.arrive!(trip, driver)
    TripLifecycle.start!(trip, driver)
    TripLifecycle.complete!(trip, driver)
    online_driver # drove nothing today

    2.times { DailyStatementJob.perform_now }
    statements = SmsSender::TestAdapter.deliveries.select { |sms| sms.to == driver.user.phone }
    expect(statements.size).to eq(1)
    expect(statements.sole.body).to start_with("Taxi AM за сегодня: 1 поездок")
    expect(DailyStatement.count).to eq(1)
  end
end
