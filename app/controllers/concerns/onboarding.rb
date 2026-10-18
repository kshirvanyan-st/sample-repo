# Sends signed-in users who haven't finished their profile to the onboarding wizard.
module Onboarding
  extend ActiveSupport::Concern

  included do
    before_action :require_onboarding
  end

  class_methods do
    def skip_onboarding(**options)
      skip_before_action :require_onboarding, **options
    end
  end

  private
    def require_onboarding
      if authenticated? && !Current.user.onboarded?
        redirect_to onboarding_path(Profile::ONBOARDING_STEPS.first)
      end
    end
end
