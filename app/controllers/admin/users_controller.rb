module Admin
  class UsersController < BaseController
    before_action :set_user, except: :index
    before_action :refuse_self, except: :index
    rate_limit to: 60, within: 1.minute, except: :index, by: -> { Current.user.id }

    def index
      @users = User.order(created_at: :desc).limit(100)
      if (digits = params[:q].to_s.gsub(/\D/, "")).present?
        @users = @users.where("phone LIKE ?", "%#{User.sanitize_sql_like(digits)}%")
      end
    end

    def role
      Moderation.change_role!(@user, to: params.require(:role), by: Current.user)
      redirect_to admin_users_path(q: params[:q]), notice: t(".changed", user: @user.display_name, role: t("roles.#{@user.role}"))
    rescue ArgumentError, ActiveRecord::RecordInvalid
      redirect_to admin_users_path(q: params[:q]), alert: t(".invalid")
    end

    def ban
      Moderation.ban!(@user, by: Current.user)
      redirect_to admin_users_path(q: params[:q]), notice: t(".banned", user: @user.display_name)
    end

    def unban
      Moderation.unban!(@user, by: Current.user)
      redirect_to admin_users_path(q: params[:q]), notice: t(".unbanned", user: @user.display_name)
    end

    private
      def set_user
        @user = User.find(params[:id])
      end

      # An admin can't demote or ban themselves and lock everyone out.
      def refuse_self
        redirect_to admin_users_path, alert: t("admin.users.self") if @user == Current.user
      end
  end
end
