module Drop
  module Commands
    class Base
      PRODUCT_SLUG = "et90-extra-time"

      def self.call(message)
        new(message).call
      end

      def initialize(message)
        @message = message
      end

      private
        attr_reader :message

        def product
          @product ||= DropProduct.includes(:drop_variants).find_by!(slug: PRODUCT_SLUG)
        end

        def guest_actor
          "guest-#{rand(100..999)}"
        end
    end
  end
end
