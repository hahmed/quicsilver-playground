class DocPage < ApplicationRecord
  validates :title, :slug, :summary, :body, :category, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :title) }

  def to_param
    slug
  end

  def score
    upvotes - downvotes
  end
end
