module Drop
  module Streams
    class Activity
      HEARTBEAT_INTERVAL = 15

      def self.call(stream:, codec:)
        new(stream, codec).call
      end

      def initialize(stream, codec)
        @stream = stream
        @codec = codec
      end

      def call
        queue = DropRoom.subscribe
        write(Drop::Payload.snapshot(product))

        loop do
          payload = queue.pop
          write(payload)
        rescue ClosedQueueError
          break
        end
      ensure
        DropRoom.unsubscribe(queue) if queue
        stream.close
      end

      private
        attr_reader :stream, :codec

        def product
          @product ||= DropProduct.includes(:drop_variants).find_by!(slug: "et90-extra-time")
        end

        def write(payload)
          puts "[Drop::Streams::Activity] write type=#{payload[:type] || payload['type']}" if ENV["DROP_DEBUG"]
          stream.write_message(codec.encode(payload))
        end
    end
  end
end
