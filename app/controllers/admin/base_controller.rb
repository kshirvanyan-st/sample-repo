# Moderators and admins only. Everyone else gets a 404, so the area isn't advertised.
class Admin::BaseController < ApplicationController
  before_action :require_staff
  layout "admin"

  rescue_from Moderation::NotAllowed do |error|
    redirect_back_or_to admin_root_path, alert: error.message, status: :see_other
  end

  private
    def require_staff
      raise ActionController::RoutingError, "Not Found" unless Current.user&.staff?
    end

    def moderation
      @moderation ||= Moderation.new(Current.user)
    end
end
