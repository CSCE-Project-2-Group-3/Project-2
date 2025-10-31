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
      expect(response).to redirect_to(conversations_path)
      expect(flash[:notice]).to match(/cannot start/)
    end

    it "falls back to user_id when recipient_id is missing" do
      post conversations_path, params: { user_id: user2.id }
      expect(response).to redirect_to(conversation_path(assigns(:conversation)))
      expect(Conversation.count).to eq(1)
    end

    it "falls back to expense_author_id when other keys are absent" do
      post conversations_path, params: { expense_author_id: user2.id }
      expect(response).to redirect_to(conversation_path(assigns(:conversation)))
      expect(Conversation.count).to eq(1)
    end

    it "redirects with an alert when the recipient cannot be resolved" do
      post conversations_path
      expect(response).to redirect_to(conversations_path)
      expect(flash[:alert]).to eq("Recipient not found.")
      expect(Conversation.count).to eq(0)
    end

    it "redirects with an alert when the recipient id does not exist" do
      post conversations_path, params: { recipient_id: 0 }
      expect(response).to redirect_to(conversations_path)
      expect(flash[:alert]).to eq("Recipient not found.")
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

  context "when user is not signed in" do
    before { sign_out user1 }

    it "redirects to the sign in page for index" do
      get conversations_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
