module Api
  class DropController < ApplicationController
    def show
      product = DropProduct.includes(:drop_variants).find_by!(slug: "et90-extra-time")
      render json: DropSerializer.product(product)
    end
  end
end
