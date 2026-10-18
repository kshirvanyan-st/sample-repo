# Step 1 of sign-in: the phone number. A 6-digit code goes out by SMS and step 2 is
# VerificationsController. New and known numbers get the same response.
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # Per IP and per number, so nobody can flood a phone with texts or burn the SMS budget.
  rate_limit to: 10, within: 1.hour, only: :create, name: "ip", with: -> { redirect_to new_session_path, alert: t("sessions.rate_limited") }
  rate_limit to: 3, within: 10.minutes, only: :create, name: "phone", by: -> { phone_param || request.remote_ip },
    with: -> { redirect_to new_session_path, alert: t("sessions.rate_limited") }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    if (phone = phone_param).nil?
      @phone = params[:phone]
      flash.now[:alert] = t(".invalid_phone")
      render :new, status: :unprocessable_content
    elsif PhoneVerification.cooling_down?(phone)
      session[:pending_phone] = phone
      redirect_to new_verification_path, alert: t(".cooling_down")
    else
      code = PhoneVerification.issue!(phone, ip_address: request.remote_ip)
      SmsSender.deliver(to: phone, body: t("sms.sign_in_code", code: code))
      session[:pending_phone] = phone
      redirect_to new_verification_path, notice: code_sent_notice(code)
    end
  rescue SmsSender::DeliveryError => e
    Rails.logger.warn "Sign-in SMS failed: #{e.message}"
    redirect_to new_session_path, alert: t(".delivery_failed")
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end

  private
    def phone_param
      User.normalize_phone(params[:phone])
    end

    # Development has no SMS, so the code is shown on the page there.
    def code_sent_notice(code)
      Rails.env.development? ? "#{t(".code_sent")} (#{code})" : t(".code_sent")
    end
end
