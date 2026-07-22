class Message < ApplicationRecord
  validates :author, presence: true, length: { maximum: 80 }
  validates :body, presence: true, length: { maximum: 1_000 }
end
