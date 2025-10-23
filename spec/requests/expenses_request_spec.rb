# spec/requests/expenses_request_spec.rb
require 'rails_helper'

RSpec.describe 'ExpensesController', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:category) { create(:category) }
  let!(:own_expense) { create(:expense, user: user, category: category, title: 'My Lunch') }
  let(:group) { create(:group) }
  let!(:shared_expense) do
    create(:group_membership, user: user, group: group)
    create(:group_membership, user: other_user, group: group)
    create(:expense, :with_group, user: other_user, group: group, category: category, title: 'Shared Dinner', participant_users: [user])
  end
  let!(:other_expense) { create(:expense, user: other_user, category: category, title: 'Someone Else') }

  before { sign_in user }

  it 'renders only expenses the user is involved in' do
    get expenses_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('My Lunch')
    expect(response.body).to include('Shared Dinner')
    expect(response.body).not_to include('Someone Else')
  end

  it 'updates an expense successfully' do
    patch expense_path(own_expense), params: { expense: { title: 'Updated Expense' } }
    expect(response).to redirect_to(expenses_path)
    follow_redirect!
    expect(response.body).to include('Updated Expense')
  end
end
