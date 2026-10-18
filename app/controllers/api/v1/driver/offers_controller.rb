module Api
  module V1
    module Driver
      class OffersController < BaseController
        before_action :set_offer

        def accept
          Dispatch.accept!(@offer)
          render_state
        end

        def decline
          Dispatch.decline!(@offer)
          render_state
        end

        private
          def set_offer
            @offer = @driver.trip_offers.find(params[:id])
          end
      end
    end
  end
end
