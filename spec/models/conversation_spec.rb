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
end
