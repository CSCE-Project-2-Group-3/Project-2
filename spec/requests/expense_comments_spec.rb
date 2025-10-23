require 'rails_helper'

RSpec.describe 'Expense comments', type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:expense) { create(:expense, user: user, category: category) }

  before { sign_in user }

  it 'creates a comment for an expense' do
    expect do
      post expense_comments_path(expense), params: { comment: { body: 'Great job' } }
    end.to change { expense.comments.count }.by(1)

    follow_redirect!
    expect(response.body).to include('Comment posted successfully')
  end

  it 'rejects blank comments' do
    post expense_comments_path(expense), params: { comment: { body: '' } }
    follow_redirect!
    expect(response.body).to include('Body can&#39;t be blank')
  end
end
