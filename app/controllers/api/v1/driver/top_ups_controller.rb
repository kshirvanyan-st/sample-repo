module Api
  module V1
    module Driver
      class TopUpsController < BaseController
        rate_limit to: 10, within: 10.minutes, by: -> { Current.user.id }, with: -> { render_error("rate_limited", :too_many_requests) }

        def create
          raise Dispatch::Error, "payments_off" unless Payments.enabled?

          top_up = TopUp.new(driver_profile: @driver, amount: params[:amount].to_i, provider: Payments.adapter.name)
          raise Dispatch::Error, "bad_amount" unless top_up.save

          render json: { id: top_up.id, checkout_url: Payments.adapter.checkout_path(top_up) }, status: :created
        end
      end
    end
  end
end
