class ProfilesController < ApplicationController
  def show
    @profile = Profile.where.not(onboarded_at: nil).find(params[:id])
    @photos = @profile.visible_photos_for(Current.user)
  end
end
