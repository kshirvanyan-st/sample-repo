# Specs tagged :osrm need a real OSRM server (the CI "routing" job starts one and sets ROUTING_ADAPTER=osrm).
RSpec.configure do |config|
  config.filter_run_excluding osrm: true unless ENV["ROUTING_ADAPTER"] == "osrm"
end

# :concurrency specs commit for real and need extra connections; the CI "dispatch" job runs them.
RSpec.configure do |config|
  config.filter_run_excluding concurrency: true unless ENV["CONCURRENCY_SPECS"]
end
