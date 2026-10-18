RSpec.configure do |config|
  config.before do
    Rails.cache.clear
    SmsSender::TestAdapter.deliveries.clear
  end
end
