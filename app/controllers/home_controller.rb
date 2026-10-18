class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    resume_session
  end
end
