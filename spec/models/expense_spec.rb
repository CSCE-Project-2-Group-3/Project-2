require 'rails_helper'

RSpec.describe Expense, type: :model do
  let!(:category) { Category.create!(name: 'Food') }
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:group) { create(:group) }

  before { sign_in user }
  describe "POST /expenses (personal)" do
    it "creates a personal expense and redirects to /expenses" do
      post expenses_path, params: {
        expense: {
          title: "Personal Expense",
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

  describe "POST /groups/:group_id/expenses (group expense)" do
    it "creates a group expense and redirects to group page" do
      post group_expenses_path(group), params: {
        expense: {
          title: "Group Expense",
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
  
  it 'is valid with title, amount, date, and category' do
    e = Expense.new(title: 'Lunch', amount: 10.5, spent_on: Date.current, category: category)
    expect(e).to be_valid
  end

  it 'is invalid without title' do
    e = Expense.new(amount: 10, spent_on: Date.current, category: category)
    expect(e).not_to be_valid
  end

  it 'is invalid with negative amount' do
    e = Expense.new(title: 'Invalid', amount: -5, spent_on: Date.current, category: category)
    expect(e).not_to be_valid
  end
end
