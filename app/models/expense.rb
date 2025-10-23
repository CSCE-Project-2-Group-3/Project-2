class Expense < ApplicationRecord
  belongs_to :category
  #added these associations
  belongs_to :user
  belongs_to :group, optional: true
  #
  validates :title, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :spent_on, presence: true
  scope :recent, -> { order(spent_on: :desc) }
end
