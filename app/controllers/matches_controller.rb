class MatchesController < ApplicationController
  def index
    @matches = Current.user.matches.includes(user_a: :profile, user_b: :profile).order(created_at: :desc)
  end

  def destroy
    Current.user.matches.find(params[:id]).destroy
    redirect_to matches_path, notice: "Unmatched.", status: :see_other
  end
end
