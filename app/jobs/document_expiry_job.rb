# Daily: texts approved drivers 30 and 7 days before their license, registration or insurance
# expires, and suspends them once it has (they can then upload the new document and resubmit).
class DocumentExpiryJob < ApplicationJob
  queue_as :default

  def perform(today = Date.current)
    DriverProfile.approved.includes(:user, :vehicle).find_each do |profile|
      profile.expiring_documents.each do |document, expires_on|
        next unless expires_on && (stage = stage_for(expires_on, today))
        next unless ExpiryNotice.record!(profile, document: document, expires_on: expires_on, stage: stage)

        notify(profile, document, expires_on, stage)
        break if profile.suspended?
      end
    end
  end

  private
    def stage_for(expires_on, today)
      if expires_on < today then "expired"
      elsif expires_on <= today + 7 then "7_days"
      elsif expires_on <= today + 30 then "30_days"
      end
    end

    def notify(profile, document, expires_on, stage)
      I18n.with_locale(profile.user.locale || I18n.default_locale) do
        name = I18n.t("drivers.documents.#{document}")
        if stage == "expired"
          Moderation.suspend_driver!(profile, note: I18n.t("drivers.expiry.suspended_note", document: name))
        else
          SmsSender.deliver(to: profile.user.phone, body: I18n.t("drivers.expiry.reminder", document: name, date: I18n.l(expires_on, format: :long)))
        end
      end
    rescue SmsSender::DeliveryError => e
      Rails.logger.warn "Expiry reminder to driver #{profile.id} failed: #{e.message}"
    end
end
