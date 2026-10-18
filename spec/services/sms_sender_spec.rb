require "rails_helper"

RSpec.describe SmsSender do
  it "uses the configured adapter" do
    SmsSender.deliver(to: "+37491123456", body: "hello")
    expect(SmsSender::TestAdapter.deliveries.last).to have_attributes(to: "+37491123456", body: "hello")
  end

  describe SmsSender::TwilioAdapter do
    let(:messages) { double("messages") }
    let(:client) { instance_double(Twilio::REST::Client, messages: messages, "http_client=": nil) }

    before { allow(Twilio::REST::Client).to receive(:new).with("AC123", "secret").and_return(client) }

    around do |example|
      env = { "TWILIO_ACCOUNT_SID" => "AC123", "TWILIO_AUTH_TOKEN" => "secret", "TWILIO_MESSAGING_SERVICE_SID" => nil, "TWILIO_FROM" => "TaxiAM" }
      saved = env.keys.index_with { |key| ENV[key] }
      env.each { |key, value| ENV[key] = value }
      example.run
    ensure
      saved.each { |key, value| ENV[key] = value }
    end

    it "sends from TWILIO_FROM" do
      expect(messages).to receive(:create).with(to: "+37491123456", body: "hi", from: "TaxiAM")
      described_class.new.deliver(to: "+37491123456", body: "hi")
    end

    it "prefers a messaging service" do
      ENV["TWILIO_MESSAGING_SERVICE_SID"] = "MG1"
      expect(messages).to receive(:create).with(to: "+37491123456", body: "hi", messaging_service_sid: "MG1")
      described_class.new.deliver(to: "+37491123456", body: "hi")
    end

    it "wraps Twilio errors" do
      allow(messages).to receive(:create).and_raise(Twilio::REST::TwilioError, "boom")
      expect { described_class.new.deliver(to: "+37491123456", body: "hi") }.to raise_error(SmsSender::DeliveryError, "boom")
    end
  end
end
