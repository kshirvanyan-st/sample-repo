# Ends a stream after its video stopped, unless the broadcaster came back in the meantime.
class StreamEndJob < ApplicationJob
  queue_as :default
  GRACE_PERIOD = 10.seconds

  def perform(stream)
    return if stream.ended?
    return if receiving?(stream)

    stream.end!
  end

  private
    def receiving?(stream)
      stream.media_path.in?(MediaServer.new.ready_paths)
    rescue MediaServer::Unavailable
      false # can't tell; the reconcile job will correct a mistake within a minute
    end
end
