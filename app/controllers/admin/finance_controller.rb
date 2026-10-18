module Admin
  class FinanceController < BaseController
    def show
      @today = Finance.summary(Time.current.all_day)
      @month = Finance.summary(Time.current.all_month)
      @balances = Finance.balances
      @debtors = DriverProfile.where(balance: ...0).includes(:user).order(:balance).limit(20)
    end
  end
end
