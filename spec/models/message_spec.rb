require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:conversation) { create(:conversation) }
  let(:user) { conversation.user_a }

  it "is valid with a body and user" do
    message = described_class.new(conversation:, user:, body: "Hello!")
    expect(message).to be_valid
  end

  it "is invalid without a body" do
    message = described_class.new(conversation:, user:, body: "")
    expect(message).not_to be_valid
  end
end
