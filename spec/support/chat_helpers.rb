module ChatHelpers
  include Turbo::Streams::StreamName

  # Two onboarded, matched users with an open conversation.
  def matched_conversation(a: create(:user, :onboarded), b: create(:user, :onboarded))
    Conversation.open_for!(Match.between!(a, b))
  end

  # The <turbo-stream> elements broadcast to a stream while the block runs
  # (an RSpec-friendly take on Turbo::Broadcastable::TestHelper).
  def capture_turbo_stream_broadcasts(streamable)
    name = stream_name_from(streamable)
    already_sent = ActionCable.server.pubsub.broadcasts(name).size
    yield
    ActionCable.server.pubsub.broadcasts(name).drop(already_sent).map do |payload|
      Nokogiri::HTML5.fragment(JSON.parse(payload)).at("turbo-stream")
    end
  end
end

RSpec.configure do |config|
  config.include ChatHelpers
end
