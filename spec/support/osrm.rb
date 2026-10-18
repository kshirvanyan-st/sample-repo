# Specs tagged :osrm need a real OSRM server (the CI "routing" job starts one and sets ROUTING_ADAPTER=osrm).
RSpec.configure do |config|
  config.filter_run_excluding osrm: true unless ENV["ROUTING_ADAPTER"] == "osrm"
end
