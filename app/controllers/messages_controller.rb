class MessagesController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :create, with: -> { head :too_many_requests }

  def create
    @conversation = Conversation.for(Current.user).find(params[:conversation_id])
    @message = @conversation.messages.build(message_params.merge(sender: Current.user))

    if @message.save
      respond_to do |format|
        # The message itself arrives over the conversation's Turbo Stream broadcast.
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { conversation: @conversation, message: Message.new }) }
        format.html { redirect_to @conversation }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { conversation: @conversation, message: @message }), status: :unprocessable_content }
        format.html { redirect_to @conversation, alert: @message.errors.full_messages.to_sentence }
      end
    end
  end

  private
    def message_params
      params.expect(message: [ :body ])
    end
end
