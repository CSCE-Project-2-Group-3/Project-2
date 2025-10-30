class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  belongs_to :quoted_expense, class_name: "Expense", optional: true

  validates :body, presence: true

  scope :recent, -> { order(created_at: :asc) }
end
