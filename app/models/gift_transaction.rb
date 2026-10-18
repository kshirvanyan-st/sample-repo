# A gift sent to a broadcaster during a live stream: coins leave the sender's wallet and
# arrive as earnings for the broadcaster, in one transaction.
class GiftTransaction < ApplicationRecord
  class NotAllowed < StandardError; end

  belongs_to :gift
  belongs_to :stream
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  after_create_commit :broadcast_to_stream

  def self.send!(sender:, stream:, gift:)
    raise NotAllowed, "This stream isn't live" unless stream.live?
    raise NotAllowed, "You can't send gifts to yourself" if stream.user == sender
    raise NotAllowed, "This gift isn't available" unless gift.active?

    transaction do
      gift_transaction = create!(sender:, stream:, gift:, recipient: stream.user, coins: gift.coins)
      Wallet.new(sender).debit!(gift.coins, kind: :gift_sent, reference: gift_transaction)
      Wallet.new(stream.user).credit!(gift.coins, account: :earnings, kind: :gift_received, reference: gift_transaction)
      gift_transaction
    end
  end

  # Biggest gifters of a stream: [[user, coins], ...]
  def self.top_gifters(stream, limit: 5)
    totals = where(stream:).group(:sender_id).order(Arel.sql("SUM(coins) DESC")).limit(limit).sum(:coins)
    users = User.includes(:profile).where(id: totals.keys).index_by(&:id)
    totals.map { |sender_id, coins| [ users[sender_id], coins ] }
  end

  private
    def broadcast_to_stream
      broadcast_append_to [ stream, :chat ], target: "stream_comments", partial: "gift_transactions/chat_line", locals: { gift_transaction: self }
      broadcast_append_to stream, target: "gift_overlay", partial: "gift_transactions/overlay", locals: { gift_transaction: self }
      broadcast_replace_to stream, target: ActionView::RecordIdentifier.dom_id(stream, :leaderboard), partial: "gift_transactions/leaderboard", locals: { stream: stream }
      broadcast_update_to stream, targets: ".stream-earnings", html: stream.gift_coins.to_s
    end
end
