module Api
  class DropEventsController < ApplicationController
    protect_from_forgery with: :null_session

    def index
      product = DropProduct.find_by!(slug: "et90-extra-time")
      render json: product.drop_events.latest.reverse.map { |event| DropSerializer.event(event) }
    end

    def create
      product = DropProduct.find_by!(slug: "et90-extra-time")
      variant = product.drop_variants.find_by(id: params[:variant_id]) if params[:variant_id].present?
      kind = params.fetch(:kind)

      event = product.drop_events.create!(
        drop_variant: variant,
        kind: kind,
        actor: params[:actor].presence || "guest-#{rand(100..999)}",
        emoji: params[:emoji],
        body: body_for(kind, variant)
      )

      render json: { event: DropSerializer.event(event), product: DropSerializer.product(product.reload) }, status: :created
    rescue KeyError, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    private
      def body_for(kind, variant)
        case kind
        when "reaction"
          "sent #{params[:emoji]}#{variant ? " at #{variant.name}" : " into the room"}"
        when "comment"
          params.fetch(:body)
        else
          params[:body].presence || "joined the drop"
        end
      end
  end
end
