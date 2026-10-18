class ConversationsController < ApplicationController
  before_action :set_conversation, only: %i[ show read ]

  def index
    @conversations = Conversation.for(Current.user).recent_first
      .includes(match: { user_a: { profile: { photos: { image_attachment: :blob } } }, user_b: { profile: { photos: { image_attachment: :blob } } } })
  end

  def show
    @other = @conversation.other(Current.user)
    @messages = @conversation.messages.includes(:sender).last(100)
    @conversation.mark_read_by!(Current.user)
  end

  # Opens (or creates) the conversation for one of your matches.
  def create
    match = Current.user.matches.find(params[:match_id])
    redirect_to Conversation.open_for!(match)
  end

  # Called by the chat window when a message arrives while it's open.
  def read
    @conversation.mark_read_by!(Current.user)
    head :no_content
  end

  private
    def set_conversation
      @conversation = Conversation.for(Current.user).find(params[:id])
    end
end
