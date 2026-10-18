class Admin::PhotosController < Admin::BaseController
  def index
    @status = params[:status].presence_in(Photo.statuses.keys) || "pending"
    @photos = Photo.where(status: @status).includes(profile: :user, image_attachment: :blob).order(created_at: :asc).limit(60)
  end

  def update
    photo = Photo.find(params[:id])
    case params[:decision]
    when "approve" then moderation.approve_photo!(photo)
    when "reject" then moderation.reject_photo!(photo, reason: params[:reason])
    else raise Moderation::NotAllowed, "Unknown decision"
    end
    redirect_back_or_to admin_photos_path, notice: "Photo #{params[:decision]}d.", status: :see_other
  end
end
