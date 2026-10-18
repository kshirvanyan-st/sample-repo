# Tells everyone following the broadcaster, on whatever page they have open, that they went live.
class StreamLiveNotificationJob < ApplicationJob
  queue_as :default

  def perform(stream)
    return unless stream.live?

    stream.user.followers.find_each do |follower|
      Turbo::StreamsChannel.broadcast_prepend_to [ follower, :notifications ], target: "flash",
        partial: "streams/live_toast", locals: { stream: stream }
    end
  end
end
