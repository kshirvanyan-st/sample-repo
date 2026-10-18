module Admin
  class ServiceZonesController < BaseController
    before_action :set_service_zone, only: %i[ edit update ]

    def index
      @service_zones = ServiceZone.order(:name)
    end

    def new
      @service_zone = ServiceZone.new
    end

    def create
      @service_zone = ServiceZone.new
      save_zone(:new)
    end

    def edit
    end

    def update
      save_zone(:edit)
    end

    private
      def set_service_zone
        @service_zone = ServiceZone.find(params[:id])
      end

      def save_zone(form)
        attributes = params.expect(service_zone: %i[ name active area_geojson ])
        @service_zone.assign_attributes(attributes.except(:area_geojson))
        @service_zone.area_geojson = attributes[:area_geojson] if attributes.key?(:area_geojson)
        if @service_zone.errors.none? && @service_zone.save
          redirect_to admin_service_zones_path, notice: t("admin.service_zones.saved", name: @service_zone.name)
        else
          render form, status: :unprocessable_content
        end
      end
  end
end
