class BlocksController < ApplicationController
  before_action :set_profile

  def create
    Current.user.blocks_given.create_or_find_by!(blocked: @profile.user)
    redirect_to discover_path, notice: "#{@profile.display_name} is blocked. You won't see each other anymore.", status: :see_other
  end

  def destroy
    Current.user.blocks_given.find_by(blocked: @profile.user)&.destroy
    redirect_to profile_path(@profile), notice: "Unblocked.", status: :see_other
  end

  private
    # Only the blocker can find the profile again to unblock it.
    def set_profile
      @profile = Profile.where.not(onboarded_at: nil).where.not(user_id: Current.user.id).find(params[:profile_id])
      head :not_found if Block.exists?(blocker: @profile.user, blocked: Current.user)
    end
end
