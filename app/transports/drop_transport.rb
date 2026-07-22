# frozen_string_literal: true

class DropTransport < Quicsilver::WebTransport::MessageStreamEndpoint
  codec :json

  def receive(message)
    Rails.logger.info("[DropTransport] #{message.inspect}")

    case message.fetch("type")
    when "snapshot"
      snapshot
    when "reaction"
      create_reaction(message)
    when "comment"
      create_comment(message)
    when "claim"
      claim_variant(message)
    else
      error("Unknown drop command: #{message['type']}")
    end
  rescue KeyError => exception
    error(exception.message)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => exception
    error(exception.message)
  end

  private
    def product
      @product ||= DropProduct.includes(:drop_variants).find_by!(slug: "et90-extra-time")
    end

    def snapshot
      {
        type: "snapshot",
        product: DropSerializer.product(product.reload),
        events: latest_events
      }
    end

    def create_reaction(message)
      event = product.drop_events.create!(
        kind: "reaction",
        actor: message["actor"].presence || guest_actor,
        emoji: message["emoji"],
        body: "sent #{message['emoji']} into the room"
      )

      event_response(event)
    end

    def create_comment(message)
      event = product.drop_events.create!(
        kind: "comment",
        actor: message["actor"].presence || "you",
        body: message.fetch("body")
      )

      event_response(event)
    end

    def claim_variant(message)
      variant = product.drop_variants.find(message.fetch("variant_id"))
      claimed = variant.claim!

      event = product.drop_events.create!(
        drop_variant: variant,
        kind: claimed.positive? ? "claim" : "sold_out",
        actor: message["actor"].presence || guest_actor,
        body: claimed.positive? ? "claimed #{variant.name}" : "tried to claim #{variant.name}, but it was sold out"
      )

      maybe_create_milestone!(product.reload)

      event_response(event, claimed: claimed.positive?)
    end

    def maybe_create_milestone!(product)
      count = product.claimed_count
      return unless [25, 50, 100, 250, 500, 1_000].include?(count)

      product.drop_events.create!(
        kind: "milestone",
        emoji: "✨",
        body: "#{count} claims unlocked Final Whistle"
      )
    end

    def event_response(event, claimed: nil)
      response = {
        type: "event",
        event: DropSerializer.event(event),
        product: DropSerializer.product(product.reload),
        events: latest_events
      }
      response[:claimed] = claimed unless claimed.nil?
      response
    end

    def latest_events
      product.drop_events.latest.reverse.map { |event| DropSerializer.event(event) }
    end

    def error(message)
      { type: "error", error: message }
    end

    def guest_actor
      "guest-#{rand(100..999)}"
    end
end
