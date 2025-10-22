# spec/requests/expenses_request_spec.rb
require 'rails_helper'

RSpec.describe 'ExpensesController', type: :request do
  include Devise::Test::IntegrationHelpers  # ✅ Required for sign_in

  let(:user) { User.create!(email: 'req@example.com', password: 'password123') }
  let!(:category) { Category.create!(name: 'Utilities') }
  let!(:expense) { Expense.create!(title: 'Test Expense', amount: 15, spent_on: Date.current, category: category) }

  before { sign_in user }

  it 'renders the index page' do
    get expenses_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Expense')
  end

  it 'updates an expense successfully' do
    patch expense_path(expense), params: { expense: { title: 'Updated Expense' } }
    expect(response).to redirect_to(expenses_path)
    follow_redirect!
    expect(response.body).to include('Updated Expense')
  end
end
