require "rails_helper"

RSpec.describe "Stream jobs" do
  describe StreamLiveNotificationJob do
    it "tells each follower the broadcaster went live" do
      stream = create(:stream, :live, title: "Late night talk")
      fan = create(:user, :onboarded)
      fan.follow(stream.user)

      broadcasts = capture_turbo_stream_broadcasts([ fan, :notifications ]) { described_class.perform_now(stream) }
      expect(broadcasts.sole["action"]).to eq("prepend")
      expect(broadcasts.sole.to_html).to include("Late night talk")
    end
  end

  describe StreamReconcileJob do
    it "ends live streams MediaMTX no longer serves and abandoned pending ones" do
      still_live = create(:stream, :live)
      gone = create(:stream, :live)
      just_started = create(:stream, :live, started_at: 5.seconds.ago)
      abandoned = create(:stream, created_at: 2.days.ago)
      allow_any_instance_of(MediaServer).to receive(:ready_paths).and_return([ still_live.media_path ])

      described_class.perform_now

      expect(still_live.reload).to be_live
      expect(gone.reload).to be_ended
      expect(just_started.reload).to be_live
      expect(abandoned.reload).to be_ended
    end

    it "starts pending streams that MediaMTX is already receiving" do
      stream = create(:stream)
      allow_any_instance_of(MediaServer).to receive(:ready_paths).and_return([ stream.media_path ])
      described_class.perform_now
      expect(stream.reload).to be_live
    end

    it "does nothing when the media server is unreachable" do
      stream = create(:stream, :live)
      allow_any_instance_of(MediaServer).to receive(:ready_paths).and_raise(MediaServer::Unavailable, "down")
      expect { described_class.perform_now }.not_to raise_error
      expect(stream.reload).to be_live
    end
  end
end
