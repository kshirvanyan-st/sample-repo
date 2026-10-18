# "Get help": riders and drivers open tickets (lost item, complaint, fare, other) and talk to staff.
class SupportTicketsController < ApplicationController
  before_action :set_ticket, only: %i[ show reply ]
  rate_limit to: 10, within: 10.minutes, only: %i[ create reply ], by: -> { Current.user.id }

  def index
    @tickets = Current.user.support_tickets.order(updated_at: :desc).limit(50)
  end

  def new
    @ticket = Current.user.support_tickets.new(kind: params[:kind].presence_in(SupportTicket::USER_KINDS) || "other", trip: own_trip)
  end

  def create
    body = params[:body].to_s.strip.first(2000)
    kind = params[:kind].presence_in(SupportTicket::USER_KINDS)
    if body.blank? || kind.nil?
      @ticket = Current.user.support_tickets.new(kind: kind || "other", trip: own_trip)
      flash.now[:alert] = t(".invalid")
      return render(:new, status: :unprocessable_content)
    end
    redirect_to Support.open!(user: Current.user, kind: kind, body: body, trip: own_trip), notice: t(".sent")
  end

  def show
  end

  def reply
    body = params[:body].to_s.strip.first(2000)
    Support.reply!(@ticket, author: Current.user, body: body) if body.present?
    redirect_to @ticket
  end

  private
    def set_ticket
      @ticket = Current.user.support_tickets.find(params[:id])
    end

    # A trip the user took part in, as rider or driver.
    def own_trip
      return if params[:trip_id].blank?

      trips = Trip.where(rider: Current.user)
      trips = trips.or(Trip.where(driver_profile: Current.user.driver_profile)) if Current.user.driver_profile
      trips.find_by(id: params[:trip_id])
    end
end
