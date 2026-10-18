module SmsSender
  class TestAdapter
    Message = Data.define(:to, :body)

    def self.deliveries
      @deliveries ||= []
    end

    def deliver(to:, body:)
      self.class.deliveries << Message.new(to: to, body: body)
    end
  end
end
