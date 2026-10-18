class ProfilesController < ApplicationController
  def show
    @profile = Profile.visible.find(params[:id])
    raise ActiveRecord::RecordNotFound if blocked_by_profile_owner?
    @photos = @profile.visible_photos_for(Current.user)
  end

  private
    # Blockers can still open the profile to unblock; the blocked person can't see it.
    def blocked_by_profile_owner?
      Block.exists?(blocker: @profile.user, blocked: Current.user)
    end
end
