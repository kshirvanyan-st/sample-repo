class StreamCommentsController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: :create, with: -> { head :too_many_requests }

  def create
    stream = Stream.where.not(user_id: Current.user.blocked_user_ids).find(params[:stream_id])
    comment = stream.comments.build(body: params.dig(:stream_comment, :body), user: Current.user)

    if comment.save
      render turbo_stream: turbo_stream.replace("stream_comment_form", partial: "stream_comments/form", locals: { stream: stream })
    else
      head :unprocessable_content
    end
  end

  # Broadcasters moderate their own chat.
  def destroy
    Current.user.streams.find(params[:stream_id]).comments.find(params[:id]).destroy
    head :no_content
  end
end
