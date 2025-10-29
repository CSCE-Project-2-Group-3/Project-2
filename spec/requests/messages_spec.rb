require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:conversation) { create(:conversation) }
  let(:user) { conversation.user_a }

  before { sign_in user }

  describe "POST /messages" do
    it "creates a message for participant" do
      post messages_path, params: { conversation_id: conversation.id, message: { body: "Hey!" } }
      expect(response).to redirect_to(conversation_path(conversation, anchor: "message-#{Message.last.id}"))
      expect(conversation.messages.last.body).to eq("Hey!")
    end

    it "blocks non-participants" do
      stranger = create(:user)
      sign_out user
      sign_in stranger

      post messages_path, params: { conversation_id: conversation.id, message: { body: "Hey!" } }
      expect(response).to redirect_to(conversations_path)
      expect(flash[:alert]).to match(/Not authorized/)
      expect(Message.where(conversation_id: conversation.id)).to be_empty
    end

    it "re-renders the conversation when the message is invalid" do
      post messages_path, params: { conversation_id: conversation.id, message: { body: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template("conversations/show")
      expect(conversation.messages).to be_empty
    end
  end
end
