# Counts who is watching: each open watch page holds one subscription.
class StreamPresenceChannel < ApplicationCable::Channel
  def subscribed
    @stream = Stream.live.find_by(id: params[:stream_id])
    return reject unless @stream && @stream.user != current_user && !current_user.blocked_with?(@stream.user)

    @connection_token = SecureRandom.uuid
    @stream.viewers.create!(user: current_user, connection_token: @connection_token)
    @stream.refresh_viewer_count!
  end

  def unsubscribed
    return unless @connection_token

    StreamViewer.where(connection_token: @connection_token).delete_all
    @stream.reload.refresh_viewer_count! if @stream.reload.live?
  end
end
