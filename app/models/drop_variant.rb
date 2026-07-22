class DropVariant < ApplicationRecord
  belongs_to :drop_product

  validates :name, :sku, :image_path, presence: true
  validates :position, :stock, :claimed_count, presence: true

  def claim!(quantity = 1)
    with_lock do
      claimed = [quantity, stock].min
      update!(stock: stock - claimed, claimed_count: claimed_count + claimed) if claimed.positive?
      claimed
    end
  end
end
