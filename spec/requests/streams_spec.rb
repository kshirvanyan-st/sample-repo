require "rails_helper"

RSpec.describe "Streams", type: :request do
  let(:user) { create(:user, :onboarded) }

  before { sign_in_as(user) }

  it "creates a stream from the Go live page and opens the studio" do
    get go_live_path
    expect(response.body).to include("Continue to studio")

    post streams_path, params: { stream: { title: "Sunday Q&A", category: "dating_talk" } }
    stream = user.streams.last
    expect(response).to redirect_to(studio_stream_path(stream))
    expect(stream).to have_attributes(title: "Sunday Q&A", category: "dating_talk", status: "pending")

    get go_live_path
    expect(response).to redirect_to(studio_stream_path(stream))
  end

  it "shows OBS settings in the studio" do
    stream = create(:stream, user: user)
    get studio_stream_path(stream)
    expect(response.body).to include(user.reload.stream_key, "rtmp://localhost:1935/live")
  end

  it "keeps other people out of your studio" do
    get studio_stream_path(create(:stream))
    expect(response).to have_http_status(:not_found)
  end

  it "ends a stream and disconnects the publisher" do
    stream = create(:stream, :live, user: user)
    expect_any_instance_of(MediaServer).to receive(:kick_publisher).with(stream.media_path)
    patch finish_stream_path(stream)
    expect(stream.reload).to be_ended
  end

  it "resets the stream key" do
    old_key = user.streaming_credentials!.stream_key
    patch reset_stream_key_path
    expect(user.reload.stream_key).not_to eq(old_key)
  end

  it "shows a live stream with a viewer token" do
    stream = create(:stream, :live, title: "Guitar night")
    get stream_path(stream)
    expect(response.body).to include("Guitar night", "data-playback-token-value=\"ey")
  end

  it "hides streams from people who blocked you" do
    stream = create(:stream, :live)
    create(:block, blocker: stream.user, blocked: user)
    get stream_path(stream)
    expect(response).to have_http_status(:not_found)
  end

  it "lists live streams, people you follow first" do
    popular = create(:stream, :live, title: "Popular", viewers_count: 50)
    followed = create(:stream, :live, title: "Friend", viewers_count: 1)
    create(:stream, :ended, title: "Over")
    user.follow(followed.user)

    get streams_path
    expect(response.body.index("Friend")).to be < response.body.index("Popular")
    expect(response.body).not_to include("Over")
  end

  describe "live chat" do
    let(:stream) { create(:stream, :live) }

    it "posts a comment" do
      expect {
        post stream_comments_path(stream), params: { stream_comment: { body: "Hello!" } }, as: :turbo_stream
      }.to change(stream.comments, :count).by(1)
      expect(response.body).to include(%(target="stream_comment_form"))
    end

    it "rejects comments on ended streams" do
      stream.end!
      post stream_comments_path(stream), params: { stream_comment: { body: "Hello?" } }, as: :turbo_stream
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "lets only the broadcaster remove comments" do
      comment = create(:stream_comment, stream: stream)
      delete stream_comment_path(stream, comment)
      expect(response).to have_http_status(:not_found)

      own = create(:stream, :live, user: user)
      own_comment = create(:stream_comment, stream: own)
      delete stream_comment_path(own, own_comment)
      expect(StreamComment.exists?(own_comment.id)).to be(false)
    end
  end
end
