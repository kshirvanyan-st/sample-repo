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

    if (viewer = StreamViewer.find_by(connection_token: @connection_token))
      Stream.update_counters(@stream.id, viewer_seconds: (Time.current - viewer.created_at).to_i) # watch time for analytics
      viewer.delete
    end
    @stream.reload.refresh_viewer_count! if @stream.reload.live?
  end
end
