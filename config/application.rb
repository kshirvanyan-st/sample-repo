require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TaxiAm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.time_zone = "Asia/Yerevan"

    # SMS delivery (see app/services/sms_sender.rb). Development logs messages.
    config.x.sms.adapter = :log

    # Maps (see app/services/routing.rb and geocoding.rb). Development uses the public OSM demo servers,
    # which allow light use only; production uses the OSRM and Nominatim accessories in config/deploy.yml.
    config.x.routing.adapter = ENV.fetch("ROUTING_ADAPTER", "osrm").to_sym
    config.x.routing.osrm_url = ENV.fetch("OSRM_URL", "https://router.project-osrm.org")
    config.x.geocoding.adapter = ENV.fetch("GEOCODING_ADAPTER", "nominatim").to_sym
    config.x.geocoding.nominatim_url = ENV.fetch("NOMINATIM_URL", "https://nominatim.openstreetmap.org")
    config.x.maps.style_url = ENV.fetch("MAP_STYLE_URL", "https://tiles.openfreemap.org/styles/liberty")
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
