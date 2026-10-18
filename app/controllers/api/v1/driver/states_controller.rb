module Api
  module V1
    module Driver
      class StatesController < BaseController
        def show
          render_state
        end

        def online
          @driver.go_online!
          render_state
        end

        def offline
          raise Dispatch::Error, "on_trip" if @driver.active_trip

          @driver.go_offline!
          render_state
        end
      end
    end
  end
end
