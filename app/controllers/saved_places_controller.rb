class SavedPlacesController < ApplicationController
  before_action :set_saved_place, only: %i[ edit update destroy ]
  rate_limit to: 30, within: 1.minute, only: %i[ create update destroy ], by: -> { Current.user.id }

  def index
    @saved_places = Current.user.saved_places.ordered
  end

  def new
    @saved_place = Current.user.saved_places.new(kind: params[:kind].presence_in(SavedPlace.kinds.keys) || "other")
  end

  def create
    @saved_place = Current.user.saved_places.new(saved_place_params)
    locate(@saved_place)
    if @saved_place.save
      redirect_to saved_places_path, notice: t(".saved")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    @saved_place.assign_attributes(saved_place_params)
    locate(@saved_place) if @saved_place.address_changed?
    if @saved_place.save
      redirect_to saved_places_path, notice: t(".saved")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @saved_place.destroy!
    redirect_to saved_places_path, notice: t(".deleted"), status: :see_other
  end

  private
    def set_saved_place
      @saved_place = Current.user.saved_places.find(params[:id])
    end

    # Finds the address on the map so the place can be picked on the "Where to?" page.
    # A geocoding outage only means the place has no map pin for now.
    def locate(place)
      place.location = place.address.present? ? Geocoding.search(place.address).first&.point : nil
    rescue HttpJson::Error => e
      Rails.logger.warn "Couldn't geocode a saved place: #{e.message}"
    end

    def saved_place_params
      params.expect(saved_place: %i[ kind label address ])
    end
end
