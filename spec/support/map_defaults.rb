# The default tariffs and Yerevan zone exist in every environment (db/seeds.rb), so specs get them too.
RSpec.configure do |config|
  config.before(:suite) do
    MapDefaults.load!
    BusinessSetting.current
  end
end
