module Drop
  module Commands
    class Comment < Base
      def call
        event = product.drop_events.create!(
          kind: "comment",
          actor: message["actor"].presence || "you",
          body: message.fetch("body")
        )

        Drop::Payload.event(event, product).tap { |payload| DropRoom.broadcast(payload) }
      end
    end
  end
end
