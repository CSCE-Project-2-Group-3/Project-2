require 'rails_helper'

RSpec.describe GroupMembership, type: :model do
  let(:user)  { User.create!(email: 'test@example.com', password: 'password') }
  let(:group) { Group.create!(name: 'Roommates 2025', join_code: 'ABC123') }

  describe 'validations' do
    it 'is valid with a user and a group' do
      membership = GroupMembership.new(user: user, group: group)
      expect(membership).to be_valid
    end

    it 'is invalid without a user' do
      membership = GroupMembership.new(group: group)
      expect(membership).not_to be_valid
    end

    it 'is invalid without a group' do
      membership = GroupMembership.new(user: user)
      expect(membership).not_to be_valid
    end

    it 'prevents duplicate user-group pairs' do
      GroupMembership.create!(user: user, group: group)
      dup = GroupMembership.new(user: user, group: group)
      expect(dup).not_to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end
end
