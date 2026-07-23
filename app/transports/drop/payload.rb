module Drop
  module Payload
    module_function

    def snapshot(product)
      {
        type: "snapshot",
        product: DropSerializer.product(product.reload),
        events: events(product)
      }
    end

    def event(event, product, claimed: nil)
      payload = {
        type: "event",
        event: DropSerializer.event(event),
        product: DropSerializer.product(product.reload),
        events: events(product)
      }
      payload[:claimed] = claimed unless claimed.nil?
      payload
    end

    def error(message)
      { type: "error", error: message }
    end

    def events(product)
      product.drop_events.latest.reverse.map { |event| DropSerializer.event(event) }
    end
  end
end
