class DropsController < ApplicationController
  def show
    @drop_product = DropProduct.includes(:drop_variants).find_by!(slug: "et90-extra-time")
    @drop_events = @drop_product.drop_events.latest.reverse
  end
end
