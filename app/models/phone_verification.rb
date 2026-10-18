# A one-time sign-in code sent by SMS. Only an HMAC of the code is stored; codes expire after
# TTL, allow MAX_ATTEMPTS guesses, work once, and issuing a new one voids the previous ones.
class PhoneVerification < ApplicationRecord
  TTL = 5.minutes
  MAX_ATTEMPTS = 5
  RESEND_COOLDOWN = 30.seconds

  scope :pending, -> { where(consumed_at: nil).where(expires_at: Time.current..).where(attempts: ...MAX_ATTEMPTS) }

  # Returns the plain code, which only ever goes into the SMS.
  def self.issue!(phone, ip_address: nil)
    code = SecureRandom.random_number(10**6).to_s.rjust(6, "0")
    transaction do
      where(phone: phone, consumed_at: nil).update_all(consumed_at: Time.current)
      create!(phone: phone, ip_address: ip_address, code_digest: digest(phone, code), expires_at: TTL.from_now)
    end
    code
  end

  # True once for the right code. Every guess counts towards MAX_ATTEMPTS.
  def self.verify(phone, code)
    transaction do
      verification = pending.where(phone: phone).order(created_at: :desc).lock.first
      next false unless verification

      verification.increment!(:attempts)
      if ActiveSupport::SecurityUtils.secure_compare(verification.code_digest, digest(phone, code.to_s.gsub(/\D/, "")))
        verification.update!(consumed_at: Time.current)
        true
      else
        false
      end
    end
  end

  def self.cooling_down?(phone)
    where(phone: phone, created_at: RESEND_COOLDOWN.ago..).exists?
  end

  def self.digest(phone, code)
    OpenSSL::HMAC.hexdigest("SHA256", key, "#{phone}:#{code}")
  end

  def self.key
    @key ||= Rails.application.key_generator.generate_key("phone_verification", 32)
  end
end
