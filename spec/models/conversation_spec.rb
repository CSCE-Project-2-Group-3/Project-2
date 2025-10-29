require 'rails_helper'

RSpec.describe Conversation, type: :model do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  it "is valid with two different users" do
    conversation = described_class.new(user_a: user1, user_b: user2)
    expect(conversation).to be_valid
  end

  it "is invalid with identical users" do
    conversation = described_class.new(user_a: user1, user_b: user1)
    expect(conversation).to_not be_valid
  end

  it "finds or creates a unique conversation between two users" do
    c1 = described_class.find_or_create_between(user1, user2)
    c2 = described_class.find_or_create_between(user2, user1)
    expect(c1).to eq(c2)
    expect(described_class.count).to eq(1)
  end

  it "returns the other user correctly" do
    conversation = described_class.create!(user_a: user1, user_b: user2)
    expect(conversation.other_user(user1)).to eq(user2)
    expect(conversation.other_user(user2)).to eq(user1)
  end

  it "returns nil when other_user is not a participant" do
    conversation = described_class.create!(user_a: user1, user_b: user2)
    outsider = create(:user)
    expect(conversation.other_user(outsider)).to be_nil
  end

  describe ".between" do
    it "finds conversations regardless of user order" do
      conversation = described_class.create!(user_a: user1, user_b: user2)
      expect(described_class.between(user2, user1)).to include(conversation)
    end
  end

  describe ".find_or_create_between" do
    it "returns nil when either user is blank" do
      expect(described_class.find_or_create_between(user1, nil)).to be_nil
      expect(described_class.find_or_create_between(nil, user2)).to be_nil
    end

    it "returns nil when both users are the same" do
      expect(described_class.find_or_create_between(user1, user1)).to be_nil
    end
  end

  describe "#participants" do
    it "returns both users in the conversation" do
      conversation = described_class.create!(user_a: user1, user_b: user2)
      expect(conversation.participants).to match_array([ user1, user2 ])
    end
  end

  it "delegates order_pair to the class helper" do
    conversation = described_class.create!(user_a: user1, user_b: user2)
    expect(conversation.send(:order_pair, user2.id, user1.id)).to eq([ user1.id, user2.id ])
  end
end
