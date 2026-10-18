module Admin
  class SettingsController < BaseController
    def edit
      @setting = BusinessSetting.current
    end

    def update
      @setting = BusinessSetting.current
      before = @setting.slice(:commission_percent, :min_balance)
      if @setting.update(params.expect(business_setting: %i[ commission_percent min_balance ]).merge(updated_by: Current.user))
        ModerationAction.create!(moderator: Current.user, user: Current.user, action: "change_settings",
          details: { from: before, to: @setting.slice(:commission_percent, :min_balance) })
        redirect_to edit_admin_settings_path, notice: t(".saved")
      else
        render :edit, status: :unprocessable_content
      end
    end
  end
end
