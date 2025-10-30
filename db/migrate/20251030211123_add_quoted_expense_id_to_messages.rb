class AddQuotedExpenseIdToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :quoted_expense_id, :integer
  end
end
