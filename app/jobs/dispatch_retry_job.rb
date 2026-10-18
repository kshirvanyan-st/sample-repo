# Nobody was free a moment ago: look again (Dispatch gives up after SEARCH_TIMEOUT).
class DispatchRetryJob < ApplicationJob
  queue_as :dispatch

  def perform(trip)
    Dispatch.offer_next!(trip)
  end
end
