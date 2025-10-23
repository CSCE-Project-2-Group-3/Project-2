require 'rails_helper'

RSpec.describe 'Expense requests', type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:group) { create(:group) }
  let(:other_member) { create(:user) }

  before do
    create(:group_membership, user: user, group: group)
    sign_in user
  end

  describe 'POST /expenses (personal)' do
    it 'creates a personal expense, defaults participants to creator, and redirects to /expenses' do
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
      expect(expense.participant_ids).to eq([user.id])
      expect(response).to redirect_to(expenses_path)
    end
  end

  describe 'POST /groups/:group_id/expenses (group expense)' do
    before do
      create(:group_membership, user: other_member, group: group)
    end

    it 'creates a group expense with default participants' do
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
      expect(expense.participant_ids).to eq([user.id])
      expect(response).to redirect_to(group_path(group))
    end

    it 'saves selected participants and allows creator to opt out' do
      post group_expenses_path(group), params: {
        expense: {
          title: 'Split Expense',
          amount: 75,
          spent_on: Date.today,
          category_id: category.id,
          participant_ids: [other_member.id]
        }
      }

      expense = Expense.last
      expect(expense.participant_ids).to match_array([other_member.id])
      expect(response).to redirect_to(group_path(group))
    end
  end
end

RSpec.describe Expense, type: :model do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  it 'is valid with title, amount, date, category, and user' do
    expect(build(:expense, category: category, user: user)).to be_valid
  end

  it 'is invalid without title' do
    expect(build(:expense, title: nil)).not_to be_valid
  end

  it 'is invalid with negative amount' do
    expect(build(:expense, amount: -5)).not_to be_valid
  end

  describe 'participants' do
    let(:group) { create(:group) }
    let(:member) { create(:user) }

    before do
      create(:group_membership, user: user, group: group)
      create(:group_membership, user: member, group: group)
    end

    it 'defaults to the creator when blank' do
      expense = build(:expense, user: user, category: category, participant_ids: [])
      expense.valid?
      expect(expense.participant_ids).to eq([user.id])
    end

    it 'deduplicates participant IDs' do
      expense = build(:expense, user: user, category: category, participant_ids: [member.id, member.id, user.id])
      expense.group = group
      expect(expense).to be_valid
      expect(expense.participant_ids).to match_array([member.id, user.id])
    end

    it 'allows the creator to exclude themselves when others selected' do
      expense = build(:expense, user: user, category: category, group: group, participant_ids: [member.id])
      expect(expense).to be_valid
    end

    it 'rejects participants who are not in the group' do
      outsider = create(:user)
      expense = build(:expense, user: user, category: category, group: group, participant_ids: [outsider.id])
      expect(expense).not_to be_valid
      expect(expense.errors[:participant_ids]).to include('must be members of the group')
    end

    it 'prevents personal expenses from including other users' do
      outsider = create(:user)
      expense = build(:expense, user: user, category: category, participant_ids: [outsider.id])
      expect(expense).not_to be_valid
      expect(expense.errors[:participant_ids]).to include('can only include yourself for personal expenses')
    end

    it 'drops non-numeric entries when normalizing raw ids' do
      expense = build(:expense, user: user, category: category)
      expect(expense.send(:normalize_ids, ['abc', member.id, ''])).to eq([member.id])
    end

    it 'deserializes array values unchanged' do
      expense = build(:expense, user: user, category: category)
      expect(expense.send(:deserialize_participant_ids, [member.id, user.id])).to eq([member.id, user.id])
    end

    it 'deserializes nil values to an empty array' do
      expense = build(:expense, user: user, category: category)
      expect(expense.send(:deserialize_participant_ids, nil)).to eq([])
    end

    it 'wraps scalar values in an array when deserializing' do
      expense = build(:expense, user: user, category: category)
      expect(expense.send(:deserialize_participant_ids, member.id)).to eq([member.id])
    end

    it 'falls back to an empty array when JSON parsing fails' do
      expense = build(:expense, user: user, category: category)
      expect(expense.send(:deserialize_participant_ids, '[not-json]')).to eq([])
    end
  end
end
