# Money and growth numbers: admins only (moderators see the moderation queues).
class Admin::RevenueController < Admin::BaseController
  before_action :require_admin

  def show
    @days = params[:days].to_i.presence_in([ 7, 30, 90 ]) || 30
    @report = Analytics::Revenue.new(days: @days)
  end

  private
    def require_admin
      raise ActionController::RoutingError, "Not Found" unless Current.user.admin?
    end
end
