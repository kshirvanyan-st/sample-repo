class PhotosController < ApplicationController
  before_action :set_profile
  before_action :set_photo, only: %i[ destroy make_main ]

  def index
  end

  def create
    @photo = @profile.photos.create(image: params.dig(:photo, :image))

    if @photo.persisted?
      redirect_to photos_path, notice: "Photo uploaded."
    else
      redirect_to photos_path, alert: @photo.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @profile.photos.count > 1
      @photo.destroy
      redirect_to photos_path, notice: "Photo removed.", status: :see_other
    else
      redirect_to photos_path, alert: "Your profile needs at least one photo.", status: :see_other
    end
  end

  def make_main
    @photo.make_main!
    redirect_to photos_path, notice: "Main photo updated.", status: :see_other
  end

  private
    def set_profile
      @profile = Current.user.profile
    end

    def set_photo
      @photo = @profile.photos.find(params[:id])
    end
end
