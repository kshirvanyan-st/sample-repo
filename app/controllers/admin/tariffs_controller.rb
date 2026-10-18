module Admin
  class TariffsController < BaseController
    rate_limit to: 30, within: 1.minute, only: :update, by: -> { Current.user.id }

    def index
      @tariffs = Tariff.ordered
    end

    def update
      tariff = Tariff.find(params[:id])
      if tariff.update(params.expect(tariff: Tariff::AMOUNTS).merge(updated_by: Current.user))
        redirect_to admin_tariffs_path, notice: t(".saved", name: t("vehicles.classes.#{tariff.vehicle_class}"))
      else
        redirect_to admin_tariffs_path, alert: tariff.errors.full_messages.to_sentence
      end
    end
  end
end
