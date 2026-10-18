class AdminMailer < ApplicationMailer
  # Recipients: ALERT_EMAILS (comma-separated), or every admin.
  def self.recipients
    ENV["ALERT_EMAILS"].to_s.split(",").map(&:strip).compact_blank.presence || User.admin.pluck(:email_address)
  end

  def alerts(messages)
    @messages = messages
    mail to: self.class.recipients, subject: "Spark alert: #{messages.first}"
  end
end
