class FollowsController < ApplicationController
  before_action :set_profile

  def create
    follow = Current.user.active_follows.build(followee: @profile.user)

    if follow.save
      respond_with_button
    else
      head :unprocessable_content
    end
  end

  def destroy
    Current.user.unfollow(@profile.user)
    respond_with_button
  end

  private
    def set_profile
      @profile = Profile.where.not(onboarded_at: nil).find(params[:profile_id])
    end

    def respond_with_button
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(helpers.dom_id(@profile, :follow), partial: "profiles/follow", locals: { profile: @profile }) }
        format.html { redirect_to profile_path(@profile), status: :see_other }
      end
    end
end
