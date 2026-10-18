module Admin
  # Pages for all staff: dispatchers as well as admins (the rest of Admin is admin-only).
  class StaffController < ApplicationController
    require_role :admin, :dispatcher
  end
end
