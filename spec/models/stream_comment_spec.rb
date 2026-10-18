require "rails_helper"

RSpec.describe StreamComment, type: :model do
  let(:stream) { create(:stream, :live) }

  it { is_expected.to validate_length_of(:body).is_at_most(300) }

  it "can be posted before and during the stream, not after" do
    expect(build(:stream_comment, stream: create(:stream))).to be_valid
    comment = build(:stream_comment, stream: create(:stream, :ended))
    expect(comment).not_to be_valid
    expect(comment.errors[:base]).to include("This stream has ended")
  end

  it "is broadcast to the stream's chat" do
    broadcasts = capture_turbo_stream_broadcasts([ stream, :chat ]) { create(:stream_comment, stream: stream, body: "Hello!") }
    expect(broadcasts.first["target"]).to eq("stream_comments")
    expect(broadcasts.first.to_html).to include("Hello!")
  end
end
