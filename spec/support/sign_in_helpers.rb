module SignInHelpers
  # The code from the last SMS sent to a phone (SmsSender::TestAdapter).
  def last_sms_code(phone = nil)
    message = SmsSender::TestAdapter.deliveries.reverse.find { |sms| phone.nil? || sms.to == phone }
    message&.body.to_s[/\d{6}/]
  end

  def sign_in_as(user)
    post session_path, params: { phone: user.phone }
    post verification_path, params: { code: last_sms_code(user.phone) }
  end
end

RSpec.configure do |config|
  config.include SignInHelpers, type: :request
  config.include SignInHelpers, type: :system
end
