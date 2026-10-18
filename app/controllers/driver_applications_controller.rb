# "Drive with us": a user fills in their license, documents and car, saves as often as they
# like, then submits it to the admin queue (Admin::DriverApplicationsController).
class DriverApplicationsController < ApplicationController
  before_action :set_driver_profile
  before_action :require_editable, only: %i[ edit update ]
  rate_limit to: 30, within: 1.minute, only: :update, by: -> { Current.user.id }

  def show
    redirect_to edit_driver_application_path if @driver_profile.new_record?
  end

  def edit
    @driver_profile.build_vehicle unless @driver_profile.vehicle
  end

  def update
    @driver_profile.assign_attributes(driver_profile_params)
    # Saving first keeps the uploaded files even when submitting fails on a missing field.
    if @driver_profile.save && (params[:submit_application].nil? || submit)
      redirect_to driver_application_path, notice: t(params[:submit_application] ? ".submitted" : ".saved")
    else
      flash.now[:alert] = t(".invalid")
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_driver_profile
      @driver_profile = Current.user.driver_profile || Current.user.build_driver_profile
    end

    def require_editable
      redirect_to driver_application_path, alert: t("driver_applications.locked") unless @driver_profile.new_record? || @driver_profile.editable?
    end

    def submit
      @driver_profile.submit!
    rescue ActiveRecord::RecordInvalid
      @driver_profile.restore_attributes(%w[ status submitted_at ])
      false
    end

    # An empty file field would remove the file already uploaded, so blank files are dropped.
    def driver_profile_params
      permitted = params.expect(driver_profile: [ :license_number, :license_expires_on, *DriverProfile::DOCUMENTS,
        vehicle_attributes: [ :make, :model, :color, :year, :plate_number, :vehicle_class,
                              :registration_expires_on, :insurance_expires_on, *Vehicle::DOCUMENTS ] ])
      drop_blank_files(permitted, DriverProfile::DOCUMENTS)
      drop_blank_files(permitted[:vehicle_attributes], Vehicle::DOCUMENTS) if permitted[:vehicle_attributes]
      permitted
    end

    def drop_blank_files(attributes, names)
      names.each { |name| attributes.delete(name) if attributes[name].blank? }
    end
end
