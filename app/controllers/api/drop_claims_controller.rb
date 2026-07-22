module Api
  class DropClaimsController < ApplicationController
    protect_from_forgery with: :null_session

    def create
      product = DropProduct.includes(:drop_variants).find_by!(slug: "et90-extra-time")
      variant = product.drop_variants.find(params.fetch(:variant_id))
      actor = params[:actor].presence || "guest-#{rand(100..999)}"
      claimed = variant.claim!

      event = if claimed.positive?
        product.drop_events.create!(
          drop_variant: variant,
          kind: "claim",
          actor: actor,
          body: "claimed #{variant.name}"
        )
      else
        product.drop_events.create!(
          drop_variant: variant,
          kind: "sold_out",
          actor: actor,
          body: "tried to claim #{variant.name}, but it was sold out"
        )
      end

      maybe_create_milestone!(product.reload)

      render json: {
        claimed: claimed.positive?,
        event: DropSerializer.event(event),
        product: DropSerializer.product(product.reload)
      }, status: claimed.positive? ? :created : :conflict
    rescue KeyError => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    private
      def maybe_create_milestone!(product)
        count = product.claimed_count
        return unless [25, 50, 100, 250, 500, 1_000].include?(count)

        product.drop_events.create!(
          kind: "milestone",
          emoji: "✨",
          body: "#{count} claims unlocked Spark Mode"
        )
      end
  end
end
