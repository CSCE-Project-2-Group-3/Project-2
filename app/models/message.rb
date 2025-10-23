class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :body, presence: true

  scope :recent, -> { order(created_at: :asc) }
end
