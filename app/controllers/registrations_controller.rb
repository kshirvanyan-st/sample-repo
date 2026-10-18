class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  skip_onboarding
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      ahoy.track "signed_up"
      redirect_to onboarding_path(Profile::ONBOARDING_STEPS.first), notice: "Welcome to Spark! Let's set up your profile."
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def registration_params
      params.expect(user: [ :email_address, :password, :password_confirmation ])
    end
end
