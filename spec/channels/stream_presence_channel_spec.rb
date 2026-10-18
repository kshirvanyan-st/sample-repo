require "rails_helper"

RSpec.describe StreamPresenceChannel, type: :channel do
  let(:viewer) { create(:user, :onboarded) }
  let(:stream) { create(:stream, :live) }

  before { stub_connection current_user: viewer }

  it "counts the viewer while subscribed" do
    subscribe(stream_id: stream.id)
    expect(subscription).to be_confirmed
    expect(stream.reload.viewers_count).to eq(1)

    unsubscribe
    expect(stream.reload.viewers_count).to eq(0)
    expect(stream.peak_viewers).to eq(1)
  end

  it "doesn't count the broadcaster" do
    stub_connection current_user: stream.user
    subscribe(stream_id: stream.id)
    expect(subscription).to be_rejected
  end

  it "rejects streams that aren't live or are blocked" do
    subscribe(stream_id: create(:stream, :ended).id)
    expect(subscription).to be_rejected

    create(:block, blocker: stream.user, blocked: viewer)
    subscribe(stream_id: stream.id)
    expect(subscription).to be_rejected
  end
end
