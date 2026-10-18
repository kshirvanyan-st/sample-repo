# Route constraint for engines mounted under /admin (Blazer, field_test): they don't run
# our controllers' authentication, so check the session cookie here. Admins only, since
# Blazer can run SQL.
class AdminConstraint
  def self.matches?(request)
    session_id = request.cookie_jar.signed[:session_id]
    session_id.present? && Session.joins(:user).merge(User.active.admin).exists?(id: session_id)
  end
end
