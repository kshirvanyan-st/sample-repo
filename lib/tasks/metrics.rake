namespace :metrics do
  desc "Recompute DailyMetric rows for the last N days (default 90): bin/rails 'metrics:backfill[90]'"
  task :backfill, [ :days ] => :environment do |_, args|
    days = Integer(args.fetch(:days, 90))
    (days.days.ago.to_date..Date.current).each { |date| DailyMetric.compute!(date) }
    puts "Recomputed #{days + 1} days of metrics."
  end
end
