require "rails_helper"

RSpec.describe "Chats", type: :request do
  let(:user) { create(:user, :onboarded) }
  let(:other) { create(:user, :onboarded, profile_attributes: { display_name: "Nare" }) }
  let(:pair) { Match.between!(user, other) }

  before { sign_in_as(user) }

  it "opens a conversation from a match" do
    expect { post match_conversation_path(pair) }.to change(Conversation, :count).by(1)
    expect(response).to redirect_to(conversation_path(Conversation.last))

    expect { post match_conversation_path(pair) }.not_to change(Conversation, :count)
  end

  it "can't open a conversation for someone else's match" do
    post match_conversation_path(Match.between!(other, create(:user)))
    expect(response).to have_http_status(:not_found)
  end

  it "lists conversations with previews and unread counts" do
    conversation = Conversation.open_for!(pair)
    create(:message, conversation: conversation, sender: other, body: "Hello there")

    get conversations_path
    expect(response.body).to include("Nare", "Hello there")
    expect(response.body).to include(%(class="chats-count))
  end

  it "shows the conversation and marks incoming messages as read" do
    conversation = Conversation.open_for!(pair)
    incoming = create(:message, conversation: conversation, sender: other, body: "Hi!")

    get conversation_path(conversation)
    expect(response.body).to include("Hi!")
    expect(incoming.reload.read_at).to be_present
  end

  it "shows Seen when the last message you sent was read" do
    conversation = Conversation.open_for!(pair)
    create(:message, conversation: conversation, sender: user, read_at: Time.current)
    get conversation_path(conversation)
    expect(response.body).to match(%r{<p id="read_receipt"[^>]*>Seen</p>})
  end

  it "hides other people's conversations" do
    stranger_chat = matched_conversation
    get conversation_path(stranger_chat)
    expect(response).to have_http_status(:not_found)

    post conversation_messages_path(stranger_chat), params: { message: { body: "hi" } }
    expect(response).to have_http_status(:not_found)
  end

  it "sends a message and resets the form" do
    conversation = Conversation.open_for!(pair)
    expect {
      post conversation_messages_path(conversation), params: { message: { body: "How are you?" } }, as: :turbo_stream
    }.to change(conversation.messages, :count).by(1)
    expect(response.body).to include(%(target="message_form"))
    expect(conversation.messages.last).to have_attributes(sender: user, body: "How are you?")
  end

  it "rejects blank messages" do
    conversation = Conversation.open_for!(pair)
    post conversation_messages_path(conversation), params: { message: { body: "   " } }, as: :turbo_stream
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Body can&#39;t be blank")
  end

  it "marks messages read from the chat window" do
    conversation = Conversation.open_for!(pair)
    incoming = create(:message, conversation: conversation, sender: other)
    patch read_conversation_path(conversation)
    expect(response).to have_http_status(:no_content)
    expect(incoming.reload.read_at).to be_present
  end

  it "loses access after unmatching" do
    conversation = Conversation.open_for!(pair)
    delete match_path(pair)
    get conversation_path(conversation)
    expect(response).to have_http_status(:not_found)
  end
end
