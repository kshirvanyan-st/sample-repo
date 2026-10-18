class Admin::ModerationActionsController < Admin::BaseController
  def index
    @actions = ModerationAction.newest_first.includes(:moderator, :target).limit(200)
  end
end
