# The public shared-trip page listens to the same updates as the rider (status and car position,
# nothing private), for as long as the share link is active.
class SharedTripChannel < ApplicationCable::Channel
  def subscribed
    link = ShareLink.find_by(token: params[:token].to_s)
    return reject unless link&.active?

    stream_from(TripChannel.broadcasting_for(link.trip))
    transmit(TripChannel.sync(link.trip))
  end
end
