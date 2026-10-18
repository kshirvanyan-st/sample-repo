class LikesController < ApplicationController
  rate_limit to: 120, within: 1.minute, only: :create, by: -> { Current.user.id }, with: -> { head :too_many_requests }

  # Who liked me: positive likes from people you haven't rated yet.
  def index
    @profiles = Profile.visible.where(user_id: liker_ids)
      .includes(photos: { image_attachment: :blob }).order(updated_at: :desc)
  end

  def create
    kind = params[:kind].presence_in(Like.kinds.keys) or return head(:unprocessable_content)
    @target = rateable_profiles.find(params[:profile_id])
    like = Current.user.likes_given.create_or_find_by!(likee: @target.user) { |l| l.kind = kind }
    @match = Match.between(Current.user, @target.user) if like.positive?
    ahoy.track "rated", kind: like.kind, source: params[:source].presence || "deck"
    ahoy.track "matched" if @match && @match.created_at >= like.created_at # created by this like

    respond_to do |format|
      format.turbo_stream { render params[:source] == "liked_me" ? :remove_card : :next_card }
      format.html do
        redirect_back_or_to discover_path, notice: (match_notice if @match)
      end
    end
  end

  private
    def liker_ids
      Like.positive.where(likee: Current.user)
        .where.not(liker_id: Current.user.likes_given.select(:likee_id))
        .where.not(liker_id: Current.user.blocked_user_ids)
        .select(:liker_id)
    end

    def rateable_profiles
      Profile.visible
        .where.not(user_id: Current.user.id)
        .where.not(user_id: Current.user.blocked_user_ids)
    end

    def match_notice
      "It's a match with #{@target.display_name}!"
    end
    helper_method :match_notice
end
