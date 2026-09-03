module Drop
  module Streams
    # Long-lived feed of room activity.
    #
    # Subscribes to DropRoom, sends a snapshot so the client has state to
    # render immediately, then forwards broadcasts until the peer disconnects
    # or the room closes the queue.
    class Activity < Quicsilver::WebTransport::StreamHandler
      def call
        queue = DropRoom.subscribe(session: session)
        debug "subscribed"

        write Drop::Payload.snapshot(product)

        loop do
          write queue.pop
        rescue ClosedQueueError
          debug "queue closed"
          break
        end
      ensure
        DropRoom.unsubscribe(queue) if queue
        close
        debug "closed"
      end

      private
        def product
          @product ||= DropProduct.includes(:drop_variants).find_by!(slug: "et90-extra-time")
        end

        def debug(message)
          warn "[Drop::Streams::Activity] #{message}" if ENV["DROP_DEBUG"]
        end
    end
  end
end
