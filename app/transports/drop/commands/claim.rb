module Drop
  module Commands
    class Claim < Base
      def call
        variant = product.drop_variants.find(message.fetch("variant_id"))
        claimed = variant.claim!

        event = product.drop_events.create!(
          drop_variant: variant,
          kind: claimed.positive? ? "claim" : "sold_out",
          actor: message["actor"].presence || guest_actor,
          body: claimed.positive? ? "claimed #{variant.name}" : "tried to claim #{variant.name}, but it was sold out"
        )

        maybe_create_milestone!

        Drop::Payload.event(event, product, claimed: claimed.positive?).tap { |payload| DropRoom.broadcast(payload) }
      end

      private
        def maybe_create_milestone!
          count = product.reload.claimed_count
          return unless [25, 50, 100, 250, 500, 1_000].include?(count)

          milestone = product.drop_events.create!(
            kind: "milestone",
            emoji: "✨",
            body: "#{count} claims unlocked Final Whistle"
          )

          DropRoom.broadcast(Drop::Payload.event(milestone, product))
        end
    end
  end
end
