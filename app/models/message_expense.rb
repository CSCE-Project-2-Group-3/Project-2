class MessageExpense < ApplicationRecord
  belongs_to :message
  belongs_to :expense
end
