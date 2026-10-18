module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    # Anonymous connections are allowed for the public shared-trip page; every channel decides who may subscribe.
    def connect
      set_current_user
    end

    private
      def set_current_user
        if session = Session.joins(:user).merge(User.active).find_by(id: cookies.signed[:session_id])
          self.current_user = session.user
        end
      end
  end
end
