class ProfilesController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: :update, by: -> { Current.user.id }

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    @user.assign_attributes(params.expect(user: %i[ name locale ]))
    if @user.save(context: :profile)
      cookies.permanent[:locale] = @user.locale if @user.locale
      redirect_to root_path, notice: I18n.t("profiles.update.saved", locale: @user.locale || I18n.locale)
    else
      render :edit, status: :unprocessable_content
    end
  end
end
