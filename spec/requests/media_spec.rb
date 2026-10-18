require "rails_helper"

RSpec.describe "MediaMTX callbacks", type: :request do
  let(:broadcaster) { create(:user, :onboarded).streaming_credentials! }
  let(:path) { Stream.media_path_for(broadcaster) }
  let(:viewer) { create(:user, :onboarded) }

  describe "POST /media/auth" do
    it "requires the shared secret" do
      media_auth(action: "publish", path: path, token: broadcaster.stream_key, secret: "wrong")
      expect(response).to have_http_status(:unauthorized)
    end

    it "lets broadcasters publish with their stream key and opens a stream" do
      expect { media_auth(action: "publish", path: path, token: broadcaster.stream_key) }.to change(broadcaster.streams, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(broadcaster.open_stream).to have_attributes(status: "pending", ingest_protocol: "rtmp", playback_protocol: "hls")
    end

    it "accepts the key as an RTMP ?token= or as a password" do
      media_auth(action: "publish", path: path, query: "token=#{broadcaster.stream_key}")
      expect(response).to have_http_status(:ok)
      media_auth(action: "publish", path: path, password: broadcaster.stream_key)
      expect(response).to have_http_status(:ok)
      expect(broadcaster.streams.count).to eq(1)
    end

    it "reuses the stream created on the Go live page" do
      stream = create(:stream, user: broadcaster, title: "Q&A")
      expect { media_auth(action: "publish", path: path, token: broadcaster.stream_key) }.not_to change(Stream, :count)
      expect(broadcaster.open_stream).to eq(stream)
    end

    it "rejects wrong keys, unknown paths and unfinished profiles" do
      media_auth(action: "publish", path: path, token: "nope")
      expect(response).to have_http_status(:unauthorized)

      media_auth(action: "publish", path: "live/unknown", token: broadcaster.stream_key)
      expect(response).to have_http_status(:unauthorized)

      newcomer = create(:user).streaming_credentials!
      media_auth(action: "publish", path: Stream.media_path_for(newcomer), token: newcomer.stream_key)
      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses banned or suspended broadcasters" do
      broadcaster.update!(streaming_suspended_at: Time.current)
      media_auth(action: "publish", path: path, token: broadcaster.stream_key)
      expect(response).to have_http_status(:unauthorized)

      broadcaster.update!(streaming_suspended_at: nil, banned_at: Time.current)
      media_auth(action: "publish", path: path, token: broadcaster.stream_key)
      expect(response).to have_http_status(:unauthorized)
    end

    it "lets viewers with a token read a live stream" do
      stream = create(:stream, :live, user: broadcaster)
      media_auth(action: "read", path: path, query: "token=#{CGI.escape(stream.viewer_token_for(viewer))}")
      expect(response).to have_http_status(:ok)
    end

    it "rejects readers without a valid token or when the stream isn't live" do
      stream = create(:stream, user: broadcaster)
      token = stream.viewer_token_for(viewer)
      media_auth(action: "read", path: path, token: token)
      expect(response).to have_http_status(:unauthorized)

      stream.update!(status: :live)
      media_auth(action: "read", path: path, token: create(:stream, :live).viewer_token_for(viewer))
      expect(response).to have_http_status(:unauthorized)
    end

    it "lets only Rails itself use the control API" do
      media_auth(action: "api", path: "", password: media_secret)
      expect(response).to have_http_status(:ok)
      media_auth(action: "api", path: "", password: "guess")
      expect(response).to have_http_status(:unauthorized)
    end

    it "denies other actions" do
      media_auth(action: "playback", path: path, token: broadcaster.stream_key)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "hooks" do
    let!(:stream) { create(:stream, user: broadcaster) }

    it "marks the stream live when video starts and ends it after the grace period" do
      expect { media_hook(:ready, path: path) }.to have_enqueued_job(StreamLiveNotificationJob)
      expect(stream.reload).to be_live

      expect { media_hook(:not_ready, path: path) }.to have_enqueued_job(StreamEndJob).with(stream)
      expect(stream.reload).to be_live
    end

    it "opens a new stream when video arrives with none open (reconnect after it ended)" do
      stream.end!
      media_hook(:ready, path: path)
      expect(broadcaster.live_stream).to be_present.and(have_attributes(title: "#{broadcaster.profile.display_name} is live"))
    end

    it "requires the shared secret" do
      media_hook(:ready, path: path, secret: "wrong")
      expect(response).to have_http_status(:unauthorized)
      expect(stream.reload).to be_pending
    end
  end
end
