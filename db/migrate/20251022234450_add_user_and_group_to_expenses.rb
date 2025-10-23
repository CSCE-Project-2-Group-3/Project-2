class AddUserAndGroupToExpenses < ActiveRecord::Migration[8.0]
  def change
    add_reference :expenses, :user, null: false, foreign_key: true
    add_reference :expenses, :group, null: false, foreign_key: true
  end
end
