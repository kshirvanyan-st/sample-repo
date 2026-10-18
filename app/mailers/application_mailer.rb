class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM") { "Spark <no-reply@#{ENV.fetch("APP_HOST", "example.com")}>" }
  layout "mailer"
end
