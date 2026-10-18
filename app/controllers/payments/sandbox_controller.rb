# The pretend bank's checkout page (only when the sandbox adapter is on). "Pay" sends the same kind
# of signed callback a real provider would, through the same code path as the real webhook.
module Payments
  class SandboxController < ApplicationController
    before_action :require_sandbox
    before_action :set_top_up

    def show
    end

    def update
      adapter = SandboxAdapter.new
      status = params[:decision] == "pay" ? "paid" : "failed"
      body = { event_id: SecureRandom.uuid, status: status, order_id: @top_up.id, payment_id: "sandbox-#{SecureRandom.hex(6)}",
               amount: @top_up.amount }.to_json
      Payments.process_callback(adapter.name, body, { SandboxAdapter::SIGNATURE_HEADER => adapter.sign(body) })
      redirect_to driver_app_path(top_up: status)
    end

    private
      def require_sandbox
        head :not_found unless Rails.configuration.x.payments.adapter.to_s == "sandbox"
      end

      def set_top_up
        @top_up = TopUp.pending.joins(:driver_profile).where(driver_profiles: { user_id: Current.user.id }).find(params[:id])
      end
  end
end
