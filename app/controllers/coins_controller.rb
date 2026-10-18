class CoinsController < ApplicationController
  def show
    @coin_packs = CoinPack.available
    @entries = Current.user.ledger_entries.coins.newest_first.includes(:reference).limit(30)
    @purchase = Current.user.purchases.find_by(id: params[:purchase]) if params[:purchase]
  end
end
