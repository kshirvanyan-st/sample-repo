class EarningsController < ApplicationController
  def show
    @gifts = Current.user.gifts_received.includes(:gift, sender: :profile).order(created_at: :desc).limit(50)
    @by_stream = Current.user.streams.joins(:gift_transactions).group("streams.id", "streams.title")
      .order(Arel.sql("SUM(gift_transactions.coins) DESC")).limit(10).sum("gift_transactions.coins")
  end
end
