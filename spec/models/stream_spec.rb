require "rails_helper"

RSpec.describe Stream, type: :model do
  let(:stream) { create(:stream) }
  let(:viewer) { create(:user, :onboarded) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:title).is_at_most(80) }

  it "maps broadcasters to MediaMTX paths and back" do
    path = stream.media_path
    expect(path).to eq("live/#{stream.user.stream_path}")
    expect(Stream.broadcaster_for_path(path)).to eq(stream.user)
    expect(Stream.broadcaster_for_path(stream.user.stream_path)).to be_nil
    expect(Stream.broadcaster_for_path("live/")).to be_nil
  end

  it "gives users created before streaming their credentials on demand" do
    user = create(:user)
    user.update_columns(stream_path: nil, stream_key: nil)
    user.streaming_credentials!
    expect(user.reload).to have_attributes(stream_path: be_present, stream_key: be_present)
  end

  it "allows only one open stream per broadcaster" do
    expect { create(:stream, user: stream.user) }.to raise_error(ActiveRecord::RecordNotUnique)
    stream.end!
    expect(create(:stream, user: stream.user)).to be_pending
  end

  describe "viewer tokens" do
    it "are valid only for their own stream" do
      token = stream.viewer_token_for(viewer)
      expect(stream.readable_with?(token)).to be(true)
      expect(create(:stream).readable_with?(token)).to be(false)
      expect(stream.readable_with?("forged")).to be(false)
    end

    it "expire" do
      token = stream.viewer_token_for(viewer)
      travel 7.hours do
        expect(stream.readable_with?(token)).to be(false)
      end
    end
  end

  it "plays RTMP streams over HLS and WHIP streams over WebRTC" do
    expect(build(:stream, ingest_protocol: "rtmp").playback_protocol).to eq("hls")
    expect(build(:stream, ingest_protocol: "webrtc").playback_protocol).to eq("webrtc")
  end

  it "goes live once and notifies followers" do
    expect { stream.go_live! }.to have_enqueued_job(StreamLiveNotificationJob).with(stream)
    expect(stream).to be_live
    expect(stream.started_at).to be_present
  end

  it "ends and clears its viewers" do
    stream.go_live!
    stream.viewers.create!(user: viewer, connection_token: "abc")
    stream.end!
    expect(stream).to be_ended
    expect(stream.viewers).to be_empty
  end

  it "tracks the peak audience" do
    live = create(:stream, :live)
    3.times { |i| live.viewers.create!(user: create(:user), connection_token: "t#{i}") }
    live.refresh_viewer_count!
    live.viewers.first.destroy
    live.refresh_viewer_count!
    expect(live.reload).to have_attributes(viewers_count: 2, peak_viewers: 3)
  end

  it "counts a person with two tabs once" do
    live = create(:stream, :live)
    live.viewers.create!(user: viewer, connection_token: "tab1")
    live.viewers.create!(user: viewer, connection_token: "tab2")
    live.refresh_viewer_count!
    expect(live.viewers_count).to eq(1)
  end

  it "swaps the player for everyone watching when the status changes" do
    broadcasts = capture_turbo_stream_broadcasts(stream) { stream.go_live! }
    expect(broadcasts.map { |b| b["target"] }).to include("player_stream_#{stream.id}", "studio_status_stream_#{stream.id}")
  end
end
