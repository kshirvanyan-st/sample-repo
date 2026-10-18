module Api
  module V1
    module Driver
      class WalletsController < BaseController
        def show
          render json: DriverWalletSummary.new(@driver).as_json
        end
      end
    end
  end
end
