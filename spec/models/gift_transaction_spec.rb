require "rails_helper"

RSpec.describe GiftTransaction, type: :model do
  let(:stream) { create(:stream, :live) }
  let(:fan) { give_coins(create(:user, :onboarded), 100) }
  let(:rose) { create(:gift, name: "Rose", emoji: "🌹", coins: 30) }

  it "moves coins from the sender to the broadcaster's earnings" do
    GiftTransaction.send!(sender: fan, stream: stream, gift: rose)

    expect(fan.reload.coin_balance).to eq(70)
    expect(stream.user.reload).to have_attributes(earnings_balance: 30, coin_balance: 0)
    expect(stream.gift_coins).to eq(30)
  end

  it "rolls everything back when the sender can't afford it" do
    diamond = create(:gift, coins: 500)
    expect { GiftTransaction.send!(sender: fan, stream: stream, gift: diamond) }.to raise_error(Wallet::InsufficientFunds)
    expect(GiftTransaction.count).to eq(0)
    expect(fan.reload.coin_balance).to eq(100)
    expect(stream.user.reload.earnings_balance).to eq(0)
  end

  it "only works on live streams, for other people, with available gifts" do
    expect { GiftTransaction.send!(sender: fan, stream: create(:stream, :ended), gift: rose) }.to raise_error(GiftTransaction::NotAllowed)
    expect { GiftTransaction.send!(sender: stream.user, stream: stream, gift: rose) }.to raise_error(GiftTransaction::NotAllowed)
    rose.update!(active: false)
    expect { GiftTransaction.send!(sender: fan, stream: stream, gift: rose) }.to raise_error(GiftTransaction::NotAllowed)
  end

  it "shows the gift in the chat, over the video and on the leaderboard" do
    chat = nil
    stage = capture_turbo_stream_broadcasts(stream) do
      chat = capture_turbo_stream_broadcasts([ stream, :chat ]) { GiftTransaction.send!(sender: fan, stream: stream, gift: rose) }
    end

    expect(chat.sole.to_html).to include("sent", "🌹", "Rose")
    expect(stage.map { |b| b["target"] || b["targets"] }).to include("gift_overlay", "leaderboard_stream_#{stream.id}", ".stream-earnings")
  end

  it "ranks the top gifters of a stream" do
    big_fan = give_coins(create(:user, :onboarded), 200)
    GiftTransaction.send!(sender: fan, stream: stream, gift: rose)
    2.times { GiftTransaction.send!(sender: big_fan, stream: stream, gift: rose) }

    expect(GiftTransaction.top_gifters(stream)).to eq([ [ big_fan, 60 ], [ fan, 30 ] ])
  end
end
