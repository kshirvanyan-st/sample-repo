class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  skip_onboarding
  # Per IP. SIGN_IN_RATE_LIMIT raises it for load tests on staging (everyone shares one IP there).
  rate_limit to: ENV.fetch("SIGN_IN_RATE_LIMIT", 10).to_i, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password))) && user.banned?
      redirect_to new_session_path, alert: "This account has been suspended."
    elsif user
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
