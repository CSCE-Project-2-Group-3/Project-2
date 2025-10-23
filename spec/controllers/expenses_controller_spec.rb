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
      expect(Expense.last.participant_ids).to eq([ user.id ])
    end
  end

  describe 'POST #create for group expenses' do
    let(:group) { create(:group) }
    let(:member) { create(:user) }

    before do
      create(:group_membership, user: user, group: group)
      create(:group_membership, user: member, group: group)
    end

    it 'sanitizes and saves selected participants' do
      post :create, params: {
        group_id: group.id,
        expense: {
          title: 'Dinner',
          amount: 40.0,
          spent_on: Date.current,
          category_id: category.id,
          participant_ids: [ '', member.id.to_s, 'junk' ]
        }
      }

      saved = Expense.last
      expect(saved.group).to eq(group)
      expect(saved.participant_ids).to eq([ member.id ])
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
