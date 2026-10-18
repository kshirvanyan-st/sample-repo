# Serves the React driver app (app/frontend/driver) at /driver.
class DriverAppController < ApplicationController
  layout "driver_app"

  def show
    redirect_to driver_application_path unless Current.user.driver_profile&.approved?
  end
end
