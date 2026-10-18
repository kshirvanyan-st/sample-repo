require "rails_helper"

RSpec.describe Conversation, type: :model do
  let(:alice) { create(:user, :onboarded) }
  let(:bob) { create(:user, :onboarded) }
  let(:conversation) { matched_conversation(a: alice, b: bob) }

  it "has one conversation per match" do
    expect(Conversation.open_for!(conversation.match)).to eq(conversation)
  end

  it "is scoped to its two participants" do
    other = matched_conversation
    expect(Conversation.for(alice)).to eq([ conversation ])
    expect(conversation.participant?(alice)).to be(true)
    expect(other.participant?(alice)).to be(false)
  end

  it "is deleted with its match, along with its messages" do
    create(:message, conversation: conversation, sender: alice)
    conversation.match.destroy
    expect(Conversation.count).to eq(0)
    expect(Message.count).to eq(0)
  end

  it "is deleted when one person blocks the other" do
    create(:message, conversation: conversation, sender: alice)
    create(:block, blocker: bob, blocked: alice)
    expect(Conversation.exists?(conversation.id)).to be(false)
  end

  describe "#mark_read_by!" do
    it "marks only the other person's messages as read and broadcasts the receipt" do
      incoming = create(:message, conversation: conversation, sender: bob)
      outgoing = create(:message, conversation: conversation, sender: alice)

      broadcasts = capture_turbo_stream_broadcasts(conversation) { conversation.mark_read_by!(alice) }
      expect(broadcasts.map { |b| b["target"] }).to include("read_receipt")
      expect(incoming.reload.read_at).to be_present
      expect(outgoing.reload.read_at).to be_nil
    end

    it "does nothing when there's nothing unread" do
      expect(capture_turbo_stream_broadcasts(conversation) { conversation.mark_read_by!(alice) }).to be_empty
    end
  end
end
