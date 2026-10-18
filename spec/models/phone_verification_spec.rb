require "rails_helper"

RSpec.describe PhoneVerification, type: :model do
  let(:phone) { "+37491123456" }

  it "issues a 6-digit code and stores only a digest" do
    code = described_class.issue!(phone, ip_address: "127.0.0.1")
    expect(code).to match(/\A\d{6}\z/)
    expect(described_class.last.code_digest).not_to include(code)
  end

  it "accepts the right code once" do
    code = described_class.issue!(phone)
    expect(described_class.verify(phone, code)).to be(true)
    expect(described_class.verify(phone, code)).to be(false)
  end

  it "ignores spaces in the typed code" do
    code = described_class.issue!(phone)
    expect(described_class.verify(phone, "#{code[0, 3]} #{code[3, 3]}")).to be(true)
  end

  it "rejects a code for another number" do
    code = described_class.issue!(phone)
    expect(described_class.verify("+37477123456", code)).to be(false)
  end

  it "expires codes" do
    code = described_class.issue!(phone)
    travel PhoneVerification::TTL + 1.second do
      expect(described_class.verify(phone, code)).to be(false)
    end
  end

  it "stops accepting the right code after too many wrong guesses" do
    code = described_class.issue!(phone)
    wrong = code == "000000" ? "111111" : "000000"
    PhoneVerification::MAX_ATTEMPTS.times { described_class.verify(phone, wrong) }
    expect(described_class.verify(phone, code)).to be(false)
  end

  it "voids earlier codes when a new one is issued" do
    old_code = described_class.issue!(phone)
    new_code = described_class.issue!(phone)
    expect(described_class.verify(phone, old_code)).to be(false) unless old_code == new_code
    expect(described_class.verify(phone, new_code)).to be(true)
  end

  it "has a resend cooldown" do
    described_class.issue!(phone)
    expect(described_class.cooling_down?(phone)).to be(true)
    travel PhoneVerification::RESEND_COOLDOWN + 1.second do
      expect(described_class.cooling_down?(phone)).to be(false)
    end
  end
end
