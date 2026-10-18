class ReportsController < ApplicationController
  before_action :set_profile

  def new
    @report = Report.new
  end

  def create
    @report = Current.user.reports_filed.build(report_params.merge(reported: @profile.user))

    if @report.save
      redirect_to profile_path(@profile), notice: "Thanks, our team will review this report."
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def set_profile
      @profile = Profile.where.not(onboarded_at: nil).where.not(user_id: Current.user.id).find(params[:profile_id])
    end

    def report_params
      params.expect(report: %i[ reason details ])
    end
end
