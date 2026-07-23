module Drop
  module Commands
    class Snapshot < Base
      def call
        Drop::Payload.snapshot(product)
      end
    end
  end
end
