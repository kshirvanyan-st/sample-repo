# Step 2 of sign-in: the code from the SMS. The first successful sign-in creates the account.
class VerificationsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_pending_phone
  rate_limit to: 20, within: 10.minutes, only: :create, with: -> { redirect_to new_verification_path, alert: t("sessions.rate_limited") }

  def new
  end

  def create
    if PhoneVerification.verify(pending_phone, params[:code])
      user = find_or_create_user
      session.delete(:pending_phone)
      sign_in user
    else
      flash.now[:alert] = t(".wrong_code")
      render :new, status: :unprocessable_content
    end
  end

  private
    def pending_phone
      session[:pending_phone]
    end
    helper_method :pending_phone

    def require_pending_phone
      redirect_to new_session_path unless pending_phone
    end

    def find_or_create_user
      User.find_or_create_by!(phone: pending_phone) { |user| user.locale = I18n.locale.to_s }
    rescue ActiveRecord::RecordNotUnique # the same number finished signing up in another tab
      User.find_by!(phone: pending_phone)
    end

    def sign_in(user)
      if user.banned?
        redirect_to new_session_path, alert: t(".banned")
      else
        start_new_session_for user
        redirect_to user.name.blank? ? edit_profile_path : after_authentication_url, notice: t(".signed_in")
      end
    end
end
