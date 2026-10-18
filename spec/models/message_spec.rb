require "rails_helper"

RSpec.describe Message, type: :model do
  let(:alice) { create(:user, :onboarded) }
  let(:bob) { create(:user, :onboarded) }
  let(:conversation) { matched_conversation(a: alice, b: bob) }

  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_length_of(:body).is_at_most(2000) }

  it "strips whitespace" do
    expect(build(:message, body: "  hi  ").body).to eq("hi")
  end

  it "only lets participants send" do
    stranger = create(:user)
    message = build(:message, conversation: conversation, sender: stranger)
    expect(message).not_to be_valid
    expect(message.errors[:sender]).to include("isn't part of this conversation")
  end

  it "updates the conversation's last_message_at" do
    expect { create(:message, conversation: conversation, sender: alice) }.to change { conversation.reload.last_message_at }
  end

  it "knows its recipient" do
    expect(build(:message, conversation: conversation, sender: alice).recipient).to eq(bob)
  end

  it "broadcasts to the conversation and to the recipient's notifications" do
    notifications = nil
    chat = capture_turbo_stream_broadcasts(conversation) do
      notifications = capture_turbo_stream_broadcasts([ bob, :notifications ]) { create(:message, conversation: conversation, sender: alice, body: "Hi Bob") }
    end

    append = chat.find { |b| b["action"] == "append" }
    expect(append["target"]).to eq("messages")
    expect(append.to_html).to include("Hi Bob")
    expect(notifications.find { |b| b["targets"] == ".chats-count" }.to_html).to include("1")
    expect(notifications.map { |b| b["target"] }).to include("preview_conversation_#{conversation.id}")
  end

  it "counts unread messages for a user across conversations" do
    create(:message, conversation: conversation, sender: bob)
    create(:message, conversation: conversation, sender: alice)
    create(:message, conversation: matched_conversation(a: alice), sender: alice)
    other = matched_conversation(a: alice)
    create(:message, conversation: other, sender: other.other(alice))

    expect(Message.unread_for(alice).count).to eq(2)
    expect(Message.unread_for(bob).count).to eq(1)
  end
end
