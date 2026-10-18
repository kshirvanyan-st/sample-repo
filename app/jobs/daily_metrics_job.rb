# Keeps today's and yesterday's DailyMetric rows fresh (runs hourly; yesterday is redone
# so late webhooks and refunds land on the right day).
class DailyMetricsJob < ApplicationJob
  queue_as :default

  def perform(dates = [ Date.current, Date.yesterday ])
    Array(dates).each { |date| DailyMetric.compute!(date.to_date) }
  end
end
