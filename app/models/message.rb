class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  has_many :message_expenses, dependent: :destroy
  has_many :quoted_expenses, through: :message_expenses, source: :expense

  validates :body, presence: true

  scope :recent, -> { order(created_at: :asc) }
end
