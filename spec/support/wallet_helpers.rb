module WalletHelpers
  def give_coins(user, amount)
    Wallet.new(user).credit!(amount, kind: :adjustment)
    user.reload
  end
end

RSpec.configure do |config|
  config.include WalletHelpers
end
