class DiscoverController < ApplicationController
  def show
    @profile = Discovery::Feed.new(Current.user).next_profile
  end
end
