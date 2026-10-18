module Api
  module V1
    module Driver
      class TripsController < BaseController
        before_action :set_trip

        def arrive
          TripLifecycle.arrive!(@trip, @driver)
          render_state
        end

        def start
          TripLifecycle.start!(@trip, @driver)
          render_state
        end

        def complete
          TripLifecycle.complete!(@trip, @driver)
          render_state
        end

        def cancel
          TripLifecycle.cancel!(@trip, by: @driver, reason: params[:reason].to_s.first(200).presence)
          render_state
        end

        private
          def set_trip
            @trip = @driver.trips.find(params[:id])
          end
      end
    end
  end
end
