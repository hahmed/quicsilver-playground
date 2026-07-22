class DropProduct < ApplicationRecord
  has_many :drop_variants, -> { order(:position) }, dependent: :destroy
  has_many :drop_events, dependent: :destroy

  validates :name, :slug, :tagline, :hero_image_path, presence: true
  validates :slug, uniqueness: true

  def to_param
    slug
  end

  def claimed_count
    drop_variants.sum(:claimed_count)
  end

  def stock_remaining
    drop_variants.sum(:stock)
  end

  def next_milestone
    [25, 50, 100, 250, 500, 1_000].find { |milestone| milestone > claimed_count } || claimed_count
  end
end
