module Drop
  module Streams
    class Activity
      HEARTBEAT_INTERVAL = 15

      def self.call(stream:, codec:, session: nil)
        new(stream, codec, session).call
      end

      def initialize(stream, codec, session)
        @stream = stream
        @codec = codec
        @session = session
      end

      def call
        debug "subscribe start"
        queue = DropRoom.subscribe(session: session)
        debug "write initial snapshot"
        write(Drop::Payload.snapshot(product))
        debug "waiting for broadcasts"

        loop do
          payload = queue.pop
          debug "broadcast payload type=#{payload[:type] || payload['type']}"
          write(payload)
        rescue ClosedQueueError
          debug "queue closed"
          break
        end
      ensure
        debug "ensure closing"
        DropRoom.unsubscribe(queue) if queue
        stream.close
      end

      private
        attr_reader :stream, :codec, :session

        def product
          @product ||= DropProduct.includes(:drop_variants).find_by!(slug: "et90-extra-time")
        end

        def write(payload)
          debug "write type=#{payload[:type] || payload['type']}"
          stream.write_message(codec.encode(payload))
        end

        def debug(message)
          warn "[Drop::Streams::Activity] #{message}" if ENV["DROP_DEBUG"]
        end
    end
  end
end
