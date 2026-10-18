# Help requests from riders and drivers, and SOS. Staff (dispatchers and admins) work them in
# Admin → Support; new tickets appear there live.
module Support
  STAFF_ALERT_LIMIT = 10

  def self.open!(user:, kind:, body:, trip: nil, location: nil, priority: :normal)
    ticket = SupportTicket.transaction do
      SupportTicket.create!(user: user, trip: trip, kind: kind, location: location, priority: priority).tap do |created|
        created.messages.create!(author: user, body: body)
      end
    end
    Notify.support_queue(ticket)
    DriverLostItemJob.perform_later(ticket) if ticket.lost_item? && trip&.driver_profile
    ticket
  end

  def self.reply!(ticket, author:, body:, internal: false)
    message = ticket.messages.create!(author: author, body: body, internal: internal && author.staff?)
    if author.staff? && !message.internal?
      ticket.update!(status: :in_progress, assignee: ticket.assignee || author) if ticket.open?
      SupportSmsJob.perform_later(ticket.user, "safety.sms.staff_replied", id: ticket.id)
    elsif !author.staff? && ticket.resolved?
      ticket.update!(status: :open, resolved_at: nil)
    end
    message
  end

  def self.resolve!(ticket, by:)
    ticket.update!(status: :resolved, resolved_at: Time.current, assignee: ticket.assignee || by)
  end

  # SOS from a rider or driver on an active trip: an urgent ticket with where they are, a text with
  # the live link to the rider's emergency contacts, and a text to staff.
  def self.sos!(trip:, by:, location: nil)
    raise Dispatch::Error, "not_allowed" unless trip.participant?(by) && trip.status.in?(Trip::BUSY)

    location ||= (trip.driver_profile&.location&.location if trip.driver_profile&.location&.fresh?)
    ticket = open!(user: by, trip: trip, kind: :sos, priority: :urgent, location: location,
      body: I18n.t("safety.sos.ticket_body", locale: I18n.default_locale, role: by == trip.rider ? "rider" : "driver"))
    link = Rails.application.routes.url_helpers.shared_trip_url(ShareLink.for(trip).token, **url_options)
    trip.rider.emergency_contacts.each do |contact|
      SupportSmsJob.perform_later(trip.rider, "safety.sms.sos_contact", to: contact.phone, name: trip.rider.display_name, link: link)
    end
    User.where(role: %i[ admin dispatcher ]).active.limit(STAFF_ALERT_LIMIT).each do |staff|
      SupportSmsJob.perform_later(staff, "safety.sms.sos_staff", id: ticket.id, link: link)
    end
    ticket
  end

  def self.url_options
    { host: ENV.fetch("APP_HOST", "localhost:3000"), protocol: Rails.env.production? ? "https" : "http" }
  end
  private_class_method :url_options
end
