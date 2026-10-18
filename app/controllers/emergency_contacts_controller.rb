class EmergencyContactsController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: %i[ create destroy ], by: -> { Current.user.id }

  def index
    @contacts = Current.user.emergency_contacts.order(:created_at)
    @contact = Current.user.emergency_contacts.new
  end

  def create
    @contact = Current.user.emergency_contacts.new(params.expect(emergency_contact: %i[ name phone ]))
    if @contact.save
      redirect_to emergency_contacts_path, notice: t(".saved")
    else
      @contacts = Current.user.emergency_contacts.order(:created_at).where.not(id: nil)
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    Current.user.emergency_contacts.find(params[:id]).destroy!
    redirect_to emergency_contacts_path, notice: t(".deleted"), status: :see_other
  end
end
