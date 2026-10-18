# Every evening: an SMS to each driver who drove today with trips, cash collected, commission,
# cancellation payouts and the balance. Each driver gets one statement per day (DailyStatement).
class DailyStatementJob < ApplicationJob
  queue_as :default

  def perform(day = Date.current)
    range = day.in_time_zone.all_day
    DriverProfile.where(id: Trip.completed.where(completed_at: range).select(:driver_profile_id)).includes(:user).find_each do |driver|
      totals = totals_for(driver, range)
      created = DailyStatement.insert({ driver_profile_id: driver.id, day: day, totals: totals, created_at: Time.current },
        unique_by: %i[ driver_profile_id day ], returning: :id).any?
      deliver(driver, totals) if created
    end
  end

  private
    def totals_for(driver, range)
      trips = driver.trips.completed.where(completed_at: range)
      entries = driver.ledger_entries.where(created_at: range)
      { trips: trips.count, cash: trips.sum(:fare), commission: -entries.commission.sum(:amount),
        payouts: entries.cancellation_payout.sum(:amount), balance: driver.balance }
    end

    def deliver(driver, totals)
      helpers = ApplicationController.helpers
      I18n.with_locale(driver.user.locale || I18n.default_locale) do
        SmsSender.deliver(to: driver.user.phone, body: I18n.t("payments.sms.statement", trips: totals[:trips],
          cash: helpers.amd(totals[:cash]), commission: helpers.amd(totals[:commission]), balance: helpers.amd(totals[:balance])))
      end
    rescue SmsSender::DeliveryError => e
      Rails.logger.warn "Daily statement to driver #{driver.id} failed: #{e.message}"
    end
end
