# One support-related text, written in the recipient's language. `to:` sends to another number
# (an emergency contact) in the user's language.
class SupportSmsJob < ApplicationJob
  queue_as :default
  retry_on SmsSender::DeliveryError, wait: :polynomially_longer, attempts: 5

  def perform(user, key, to: nil, **values)
    I18n.with_locale(user.locale || I18n.default_locale) do
      SmsSender.deliver(to: to || user.phone, body: I18n.t(key, **values))
    end
  end
end
