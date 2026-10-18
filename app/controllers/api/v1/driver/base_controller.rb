# JSON for the driver app (app/frontend/driver). Same session cookie as the website; the app sends
# the CSRF token in the X-CSRF-Token header.
module Api
  module V1
    module Driver
      class BaseController < ApplicationController
        before_action :require_approved_driver
        rate_limit to: 60, within: 1.minute, by: -> { Current.user.id }, with: -> { render_error("rate_limited", :too_many_requests) }

        rescue_from Dispatch::Error do |error|
          render_error(error.key, :unprocessable_content)
        end

        private
          def require_approved_driver
            @driver = Current.user.driver_profile
            render_error("not_a_driver", :forbidden) unless @driver&.approved?
          end

          def render_error(key, status)
            render json: { error: key, message: t("dispatch.errors.#{key}") }, status: status
          end

          def render_state
            render json: DriverState.new(@driver.reload).as_json
          end

          # JSON clients get 401 instead of the sign-in redirect.
          def request_authentication
            render json: { error: "signed_out" }, status: :unauthorized
          end
      end
    end
  end
end
