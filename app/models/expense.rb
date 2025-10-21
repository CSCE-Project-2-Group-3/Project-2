class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :receipt, optional: true
  belongs_to :category, optional: true

  validates :amount, presence: true, numericality: true
  validates :currency, presence: true
end
