module Admin
  class BaseController < ApplicationController
    require_role :admin
  end
end
