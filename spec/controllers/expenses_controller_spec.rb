require 'rails_helper'

RSpec.describe ExpensesController, type: :controller do
  let(:user) { create(:user) }
  let!(:category) { create(:category) }

  before { sign_in user }

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
      expect(Expense.last.user).to eq(user)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes an expense' do
      expense = create(:expense, user: user, category: category)

      expect do
        delete :destroy, params: { id: expense.id }
      end.to change(Expense, :count).by(-1)
    end
  end
end
