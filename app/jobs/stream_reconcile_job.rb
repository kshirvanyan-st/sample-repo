# Safety net for missed hooks (runs every minute): starts streams MediaMTX is already
# receiving, ends "live" streams it no longer serves, and closes pending streams nobody
# started within a day.
class StreamReconcileJob < ApplicationJob
  queue_as :default
  GRACE_PERIOD = 30.seconds

  def perform
    ready = MediaServer.new.ready_paths

    # Video arriving without a live stream (missed hook, reconnect race): start one.
    ready.each do |path|
      broadcaster = Stream.broadcaster_for_path(path)
      next if broadcaster.nil? || broadcaster.live_stream || broadcaster.banned? || broadcaster.streaming_suspended?

      Stream.open_for_ingest!(broadcaster).go_live!
    end
    Stream.live.where(started_at: ...GRACE_PERIOD.ago).includes(:user).find_each do |stream|
      stream.end! unless stream.media_path.in?(ready)
    end
    Stream.pending.where(created_at: ...1.day.ago).find_each(&:end!)
  rescue MediaServer::Unavailable => e
    Rails.logger.warn("StreamReconcileJob skipped: #{e.message}")
  end
end
