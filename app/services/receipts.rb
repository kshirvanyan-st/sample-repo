# Text receipts. Sent from jobs so a slow SMS provider never holds up the trip.
module Receipts
  def self.trip_completed(trip)
    TripReceiptJob.perform_later(trip)
  end
end
