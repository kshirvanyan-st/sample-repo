class My::ProfilesController < ApplicationController
  before_action :set_profile

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path(@profile), notice: "Profile updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_profile
      @profile = Current.user.profile
    end

    def profile_params
      params.expect(profile: %i[ display_name birthdate gender looking_for city bio latitude longitude age_min age_max max_distance_km ])
    end
end
