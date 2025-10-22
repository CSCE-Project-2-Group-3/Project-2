require 'rails_helper'

RSpec.describe ExpensesController, type: :controller do
  let!(:category) { Category.create!(name: 'Transport') }

  describe 'POST #create' do
    it 'creates a new expense' do
      expect do
        post :create, params: {
          expense: {
            title: 'Bus Ticket',
            amount: 2.75,
            spent_on: Date.current,
            category_id: category.id
          }
        }
      end.to change(Expense, :count).by(1)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes an expense' do
      expense = Expense.create!(title: 'Lunch', amount: 5, spent_on: Date.current, category: category)

      expect do
        delete :destroy, params: { id: expense.id }
      end.to change(Expense, :count).by(-1)
    end
  end
end
