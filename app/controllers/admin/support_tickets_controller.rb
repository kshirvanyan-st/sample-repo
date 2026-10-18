module Admin
  class SupportTicketsController < StaffController
    before_action :set_ticket, except: :index
    rate_limit to: 60, within: 1.minute, except: %i[ index show ], by: -> { Current.user.id }

    def index
      @status = params[:status].presence_in(%w[ open in_progress resolved ])
      @tickets = SupportTicket.includes(:user, :trip, :assignee).queue.limit(100)
      @tickets = @status ? @tickets.where(status: @status) : @tickets.unresolved
      @tickets = @tickets.where(kind: params[:kind]) if params[:kind].presence_in(SupportTicket.kinds.keys)
    end

    def show
      @trip = @ticket.trip
    end

    def reply
      body = params[:body].to_s.strip.first(2000)
      Support.reply!(@ticket, author: Current.user, body: body, internal: params[:internal] == "1") if body.present?
      redirect_to admin_support_ticket_path(@ticket)
    end

    def assign
      @ticket.update!(assignee: Current.user, status: @ticket.open? ? :in_progress : @ticket.status)
      redirect_to admin_support_ticket_path(@ticket)
    end

    def resolve
      Support.resolve!(@ticket, by: Current.user)
      redirect_to admin_support_tickets_path, notice: t(".resolved", id: @ticket.id)
    end

    private
      def set_ticket
        @ticket = SupportTicket.includes(messages: :author).find(params[:id])
      end
  end
end
