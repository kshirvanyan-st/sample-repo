module CoinsHelper
  def ledger_description(entry)
    case entry.kind
    when "purchase" then "Bought #{entry.reference&.coin_pack&.name || "coins"}"
    when "gift_sent" then "Sent #{entry.reference&.gift&.then { |g| "#{g.emoji} #{g.name}" } || "a gift"}"
    when "gift_received" then "Gift received"
    when "refund" then "Refund"
    else "Adjustment"
    end
  end
end
