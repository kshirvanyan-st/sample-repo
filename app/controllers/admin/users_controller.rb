class Admin::UsersController < Admin::BaseController
  before_action :set_user, except: :index

  def index
    @users = User.includes(:profile).order(created_at: :desc).limit(50)
    if (q = params[:q].to_s.strip).present?
      @users = @users.left_joins(:profile).where("users.email_address ILIKE :q OR profiles.display_name ILIKE :q", q: "%#{User.sanitize_sql_like(q)}%")
    end
    @users = @users.where.not(banned_at: nil) if params[:filter] == "banned"
    @users = @users.where(role: %i[ moderator admin ]) if params[:filter] == "staff"
  end

  def show
    @reports = @user.reports_received.includes(:reporter).order(created_at: :desc).limit(20)
    @photos = @user.profile&.photos || Photo.none
    @streams = @user.streams.order(created_at: :desc).limit(10)
    @actions = ModerationAction.where(target: @user).or(ModerationAction.where(target: @user.streams)).newest_first.includes(:moderator).limit(20)
  end

  def ban
    moderation.ban!(@user, reason: params.require(:reason))
    redirect_to admin_user_path(@user), notice: "#{label} is banned.", status: :see_other
  end

  def unban
    moderation.unban!(@user)
    redirect_to admin_user_path(@user), notice: "#{label} is unbanned.", status: :see_other
  end

  def restore_streaming
    moderation.restore_streaming!(@user)
    redirect_to admin_user_path(@user), notice: "#{label} can stream again.", status: :see_other
  end

  def role
    moderation.change_role!(@user, params.require(:role).presence_in(User.roles.keys) || raise(Moderation::NotAllowed, "Unknown role"))
    redirect_to admin_user_path(@user), notice: "#{label} is now #{@user.role}.", status: :see_other
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def label
      @user.profile&.display_name || @user.email_address
    end
end
