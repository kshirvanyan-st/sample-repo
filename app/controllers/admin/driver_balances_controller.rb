module Admin
  # One driver's ledger, and cash top-ups or corrections recorded by an admin.
  class DriverBalancesController < BaseController
    before_action :set_driver_profile
    rate_limit to: 30, within: 1.minute, only: :create, by: -> { Current.user.id }

    def show
      @entries = @driver_profile.ledger_entries.newest_first.includes(:created_by, :reference).limit(100)
    end

    def create
      amount = params[:amount].to_i
      note = params[:note].to_s.strip.first(200)
      kind = params[:kind] == "top_up" ? :top_up : :adjustment
      return redirect_to(admin_driver_application_balance_path(@driver_profile), alert: t(".invalid")) if amount.zero? || note.blank? || (kind == :top_up && amount.negative?)

      wallet = DriverWallet.new(@driver_profile)
      LedgerEntry.transaction do
        amount.positive? ? wallet.credit!(amount, kind: kind, created_by: Current.user, note: note) : wallet.debit!(-amount, kind: kind, created_by: Current.user, note: note)
        ModerationAction.create!(moderator: Current.user, user: @driver_profile.user, action: "balance_#{kind}",
          details: { amount: amount, note: note, driver_profile_id: @driver_profile.id })
      end
      redirect_to admin_driver_application_balance_path(@driver_profile), notice: t(".saved")
    end

    private
      def set_driver_profile
        @driver_profile = DriverProfile.includes(:user).find(params[:driver_application_id])
      end
  end
end
