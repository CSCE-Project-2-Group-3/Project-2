require 'rails_helper'

RSpec.describe GroupMembership, type: :model do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  describe 'validations' do
    it 'is valid with a user and a group' do
      membership = described_class.new(user: user, group: group)
      expect(membership).to be_valid
    end

    it 'is invalid without a user' do
      membership = described_class.new(group: group)
      expect(membership).not_to be_valid
    end

    it 'is invalid without a group' do
      membership = described_class.new(user: user)
      expect(membership).not_to be_valid
    end

    it 'prevents duplicate user-group pairs' do
      described_class.create!(user: user, group: group)
      dup = described_class.new(user: user, group: group)
      expect(dup).not_to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end
end
