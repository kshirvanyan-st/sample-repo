class OfferTimeoutJob < ApplicationJob
  queue_as :dispatch

  def perform(offer)
    Dispatch.expire!(offer)
  end
end
