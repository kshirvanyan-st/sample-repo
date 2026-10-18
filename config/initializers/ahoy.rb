# Product analytics events (Ahoy), tracked server-side only: no JavaScript, no geocoding,
# IPs masked, and visit tokens not stored in cookies.
class Ahoy::Store < Ahoy::DatabaseStore
end

# The signed-in user lives in Current (Rails 8 authentication). Ahoy's visit callback runs
# before require_authentication, so resume the session from the cookie when needed.
Ahoy.user_method = ->(controller) { Current.user || controller.send(:resume_session)&.user }

Ahoy.api = false
Ahoy.geocode = false
Ahoy.mask_ips = true
Ahoy.cookies = :none
Ahoy.track_bots = false
# A visit per user per 4 hours of activity, even without events: daily active users and
# retention are counted from visits.
Ahoy.server_side_visits = true
Ahoy.visit_duration = 4.hours
