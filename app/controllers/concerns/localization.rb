# Picks the locale for each request: ?locale= (remembered in a cookie), then the cookie,
# then the browser's Accept-Language, then Armenian.
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private
    def switch_locale(&action)
      # A link Turbo prefetches on hover isn't a choice the user made, so it doesn't change the language.
      cookies.permanent[:locale] = request_locale if requested_locale && request.headers["X-Sec-Purpose"] != "prefetch"
      I18n.with_locale(request_locale, &action)
    end

    def request_locale
      @request_locale ||= requested_locale || cookies[:locale].presence_in(available_locales) || browser_locale || I18n.default_locale
    end

    # rescue_from handlers run after switch_locale has finished, so they translate through this.
    def t_request(key, **options)
      I18n.with_locale(request_locale) { I18n.t(key, **options) }
    end

    def requested_locale
      params[:locale].to_s.presence_in(available_locales)
    end

    def browser_locale
      request.headers["Accept-Language"].to_s.scan(/([a-z]{2})(?:-[A-Za-z]{2})?/).flatten.find { |code| code.in?(available_locales) }
    end

    def available_locales
      I18n.available_locales.map(&:to_s)
    end
end
