# Server-to-server callbacks from payment providers. No session or CSRF token: the signature checked
# by the adapter is the authentication.
module Payments
  class CallbacksController < ActionController::Base
    def create
      Payments.process_callback(params[:provider], request.raw_post, request.headers)
      head :ok
    rescue Payments::Error, ActiveRecord::RecordNotFound => e
      Rails.logger.warn "Rejected #{params[:provider]} payment callback: #{e.message}"
      head :bad_request
    end
  end
end
