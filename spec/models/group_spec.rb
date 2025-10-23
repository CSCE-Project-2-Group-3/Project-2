require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  describe 'validations' do
    it 'is valid with a name and join_code' do
      expect(group).to be_valid
    end

    it 'is invalid without a name' do
      group.name = nil
      expect(group).not_to be_valid
      expect(group.errors[:name]).to include("Group name can't be blank")
    end

    it 'generates a join_code automatically if not provided' do
      g = create(:group, join_code: nil)
      expect(g.join_code).to be_present
    end

    it 'ensures join_code is unique' do
      dup = described_class.new(name: 'Dup', join_code: group.join_code)
      expect(dup).not_to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:group_memberships) }
    it { should have_many(:users).through(:group_memberships) }
  end

  describe '#add_member' do
    it 'adds a user who is not yet a member' do
      group.add_member(user)
      expect(group.users).to include(user)
    end

    it 'does not duplicate membership if user already in group' do
      2.times { group.add_member(user) }
      expect(group.users.count).to eq(1)
    end
  end
end
