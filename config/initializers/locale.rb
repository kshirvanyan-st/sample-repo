# Armenian first, then Russian and English (the three languages of riders and drivers in Armenia).
Rails.application.configure do
  config.i18n.available_locales = %i[ hy ru en ]
  config.i18n.default_locale = :hy
  config.i18n.fallbacks = [ :en ]
  config.i18n.raise_on_missing_translations = Rails.env.local? ? :strict : false
end
