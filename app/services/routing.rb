# Driving distance, time and route line between two points, from OSRM (config.x.routing).
# If OSRM can't be reached the quote still works from a straight-line estimate, marked approximate.
module Routing
  Route = Data.define(:distance_m, :duration_s, :geometry, :approximate)

  ADAPTERS = { osrm: "Routing::OsrmAdapter", straight_line: "Routing::StraightLineAdapter" }.freeze

  def self.route(from, to)
    adapter.route(from, to)
  rescue HttpJson::Error => e
    Rails.logger.warn "Routing failed, using a straight-line estimate: #{e.message}"
    StraightLineAdapter.new.route(from, to)
  end

  # Driving seconds from each origin to one destination (e.g. drivers to a pickup), same order.
  def self.etas(origins, destination)
    return [] if origins.empty?

    adapter.etas(origins, destination)
  rescue HttpJson::Error => e
    Rails.logger.warn "ETA lookup failed, using straight-line estimates: #{e.message}"
    StraightLineAdapter.new.etas(origins, destination)
  end

  def self.adapter
    ADAPTERS.fetch(Rails.configuration.x.routing.adapter.to_sym).constantize.new
  end
end
