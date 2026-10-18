# Role checks for staff areas. Anyone without the role gets a 404, so the pages stay hidden.
module Authorization
  extend ActiveSupport::Concern

  class_methods do
    def require_role(*roles, **options)
      before_action(**options) { head :not_found unless Current.user&.role.to_s.in?(roles.map(&:to_s)) }
    end
  end
end
