class CoinsController < ApplicationController
  def show
    @coin_packs = CoinPack.available
    @store_variant = field_test(:coin_store_highlight, participant: Current.user)
    ahoy.track "coin_store_viewed", variant: @store_variant
    @entries = Current.user.ledger_entries.coins.newest_first.includes(:reference).limit(30)
    @purchase = Current.user.purchases.find_by(id: params[:purchase]) if params[:purchase]
  end
end
