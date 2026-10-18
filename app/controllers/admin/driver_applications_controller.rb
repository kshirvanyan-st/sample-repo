module Admin
  class DriverApplicationsController < BaseController
    STATUSES = %w[ submitted needs_changes approved suspended rejected ].freeze
    REVIEW = "review" # approved drivers whose rating fell below Ratings::REVIEW_BELOW

    before_action :set_driver_profile, except: :index
    rate_limit to: 60, within: 1.minute, except: %i[ index show ], by: -> { Current.user.id }

    def index
      @status = params[:status].presence_in(STATUSES + [ REVIEW ]) || "submitted"
      scope = @status == REVIEW ? DriverProfile.where.not(review_flagged_at: nil).order(:rating_avg) : DriverProfile.where(status: @status)
      @driver_profiles = scope.includes(:user, :vehicle).order(submitted_at: :asc, updated_at: :desc).limit(100)
      @counts = DriverProfile.where(status: STATUSES).group(:status).count.merge(REVIEW => DriverProfile.where.not(review_flagged_at: nil).count)
    end

    def show
    end

    def reviewed
      @driver_profile.update!(review_flagged_at: nil)
      ModerationAction.create!(moderator: Current.user, user: @driver_profile.user, action: "clear_review",
        details: { driver_profile_id: @driver_profile.id, note: params[:note].to_s.strip.first(500).presence }.compact)
      redirect_to admin_driver_applications_path(status: REVIEW), notice: t("admin.driver_applications.reviewed", name: @driver_profile.user.display_name)
    end

    def approve
      decide { Moderation.approve_driver!(@driver_profile, by: Current.user) }
    end

    def request_changes
      decide(note: true) { |note| Moderation.request_driver_changes!(@driver_profile, by: Current.user, note: note) }
    end

    def reject
      decide(note: true) { |note| Moderation.reject_driver!(@driver_profile, by: Current.user, note: note) }
    end

    def suspend
      decide(note: true) { |note| Moderation.suspend_driver!(@driver_profile, by: Current.user, note: note) }
    end

    private
      def set_driver_profile
        @driver_profile = DriverProfile.includes(:user, :vehicle).find(params[:id])
      end

      def decide(note: false)
        text = params[:note].to_s.strip
        return redirect_to(admin_driver_application_path(@driver_profile), alert: t("admin.driver_applications.note_required")) if note && text.blank?

        yield text.truncate(1000)
        redirect_to admin_driver_applications_path, notice: t("admin.driver_applications.#{action_name}.done", name: @driver_profile.user.display_name)
      rescue Moderation::InvalidTransition
        redirect_to admin_driver_application_path(@driver_profile), alert: t("admin.driver_applications.invalid_transition")
      end
  end
end
