module Drop
  module Commands
    class Reaction < Base
      def call
        event = product.drop_events.create!(
          kind: "reaction",
          actor: message["actor"].presence || guest_actor,
          emoji: message["emoji"],
          body: "sent #{message['emoji']} into the room"
        )

        Drop::Payload.event(event, product).tap { |payload| DropRoom.broadcast(payload) }
      end
    end
  end
end
