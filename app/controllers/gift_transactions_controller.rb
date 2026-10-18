class GiftTransactionsController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :create, with: -> { head :too_many_requests }

  def create
    stream = Stream.where.not(user_id: Current.user.blocked_user_ids).find(params[:stream_id])
    gift = Gift.available.find(params[:gift_id])
    GiftTransaction.send!(sender: Current.user, stream:, gift:)

    respond_to do |format|
      format.turbo_stream { head :no_content } # the gift appears for everyone over the stream's broadcast
      format.html { redirect_to stream }
    end
  rescue Wallet::InsufficientFunds
    respond_with_error(stream, "You need #{gift.coins} coins for #{gift.emoji} #{gift.name}.", buy_link: true)
  rescue GiftTransaction::NotAllowed => e
    respond_with_error(stream, e.message)
  end

  private
    def respond_with_error(stream, message, buy_link: false)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("gift_message", partial: "gift_transactions/message", locals: { message:, buy_link: }),
            status: :unprocessable_content
        end
        format.html { redirect_to stream, alert: message }
      end
    end
end
