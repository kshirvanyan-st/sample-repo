module SmsSender
  class LogAdapter
    def deliver(to:, body:)
      Rails.logger.info "[SMS] to #{to}: #{body}"
    end
  end
end
