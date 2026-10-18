class OnboardingController < ApplicationController
  skip_onboarding
  before_action :set_step
  before_action :set_profile

  def show
  end

  def update
    case @step
    when "photos"
      complete_photos_step
    else
      if @profile.update(profile_params)
        redirect_to onboarding_path(next_step)
      else
        render :show, status: :unprocessable_content
      end
    end
  end

  private
    def set_step
      # Look the step up in the allowlist so the rendered partial name never comes from user input.
      @step = Profile::ONBOARDING_STEPS.find { |step| step == params[:step] }
      raise ActionController::RoutingError, "Unknown onboarding step" unless @step
    end

    # The basics step creates the profile; later steps need it to exist.
    def set_profile
      @profile = Current.user.profile || Current.user.build_profile
      redirect_to onboarding_path(Profile::ONBOARDING_STEPS.first) if @profile.new_record? && @step != "basics"
    end

    def next_step
      Profile::ONBOARDING_STEPS[Profile::ONBOARDING_STEPS.index(@step) + 1]
    end

    def profile_params
      permitted = @step == "basics" ? %i[ display_name birthdate gender looking_for ] : %i[ city bio latitude longitude ]
      params.expect(profile: permitted)
    end

    def complete_photos_step
      images = Array(params.dig(:profile, :images)).compact_blank
      images.each { |image| @profile.photos.create(image: image) }

      if @profile.photos.any?
        @profile.update!(onboarded_at: Time.current)
        redirect_to root_path, notice: "Your profile is ready!"
      else
        @profile.errors.add(:base, "Add at least one photo")
        render :show, status: :unprocessable_content
      end
    end
end
