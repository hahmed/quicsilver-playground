class DropEvent < ApplicationRecord
  belongs_to :drop_product
  belongs_to :drop_variant, optional: true

  validates :kind, :body, presence: true

  scope :latest, -> { order(created_at: :desc).limit(40) }
end
