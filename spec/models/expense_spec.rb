require 'rails_helper'

RSpec.describe 'Expense requests', type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:group) { create(:group) }

  before do
    create(:group_membership, user: user, group: group)
    sign_in user
  end

  describe 'POST /expenses (personal)' do
    it 'creates a personal expense and redirects to /expenses' do
      post expenses_path, params: {
        expense: {
          title: 'Personal Expense',
          amount: 50,
          spent_on: Date.today,
          category_id: category.id
        }
      }

      expense = Expense.last
      expect(expense.user).to eq(user)
      expect(expense.group).to be_nil
      expect(response).to redirect_to(expenses_path)
    end
  end

  describe 'POST /groups/:group_id/expenses (group expense)' do
    it 'creates a group expense and redirects to group page' do
      post group_expenses_path(group), params: {
        expense: {
          title: 'Group Expense',
          amount: 100,
          spent_on: Date.today,
          category_id: category.id
        }
      }

      expense = Expense.last
      expect(expense.user).to eq(user)
      expect(expense.group).to eq(group)
      expect(response).to redirect_to(group_path(group))
    end
  end
end

RSpec.describe Expense, type: :model do
  it 'is valid with title, amount, date, category, and user' do
    expect(build(:expense)).to be_valid
  end

  it 'is invalid without title' do
    expect(build(:expense, title: nil)).not_to be_valid
  end

  it 'is invalid with negative amount' do
    expect(build(:expense, amount: -5)).not_to be_valid
  end
end
