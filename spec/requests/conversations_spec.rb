require 'rails_helper'

RSpec.describe "Conversations", type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  before { sign_in user1 }

  describe "POST /conversations" do
    it "creates or finds a conversation and redirects" do
      post conversations_path, params: { recipient_id: user2.id }
      expect(response).to redirect_to(conversation_path(assigns(:conversation)))
      expect(Conversation.count).to eq(1)
    end

    it "prevents creating a conversation with self" do
      post conversations_path, params: { recipient_id: user1.id }
      expect(response).to redirect_to(expenses_path)
      expect(flash[:notice]).to match(/cannot start/)
    end
  end

  describe "GET /conversations/:id" do
    let(:conversation) { Conversation.find_or_create_between(user1, user2) }

    it "renders show for participants" do
      get conversation_path(conversation)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Conversation with")
    end

    it "redirects unauthorized user" do
      sign_out user1
      sign_in create(:user)
      get conversation_path(conversation)
      expect(response).to redirect_to(conversations_path)
    end
  end
end
