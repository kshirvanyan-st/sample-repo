require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "rejects banned users" do
    user = create(:user, banned_at: Time.current)
    session = user.sessions.create!
    cookies.signed[:session_id] = session.id
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "accepts signed-in users" do
    user = create(:user)
    cookies.signed[:session_id] = user.sessions.create!.id
    connect "/cable"
    expect(connection.current_user).to eq(user)
  end
end
