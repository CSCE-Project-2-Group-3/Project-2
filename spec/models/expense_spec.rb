require 'rails_helper'

RSpec.describe Expense, type: :model do
  let!(:category) { Category.create!(name: 'Food') }

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
