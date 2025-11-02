require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:conversation) { create(:conversation, user_a: user, user_b: other_user) }

  before do
    sign_in user
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Message" do
        expect {
          post :create, params: { conversation_id: conversation.id, message: { body: "Test" } }
        }.to change(Message, :count).by(1)
      end

      it "redirects to the conversation" do
        post :create, params: { conversation_id: conversation.id, message: { body: "Test" } }
        expect(response).to redirect_to(conversation_path(conversation, anchor: "message-#{Message.last.id}"))
      end

      # --- THIS TEST COVERS LINE 20 ---
      it "attaches quoted expenses if provided" do
        expense = create(:expense, user: user)
        post :create, params: {
          conversation_id: conversation.id,
          message: {
            body: "Check this expense",
            quoted_expense_ids: [ expense.id ]
          }
        }

        # This will execute the `if` block on line 20
        expect(Message.last.quoted_expenses).to include(expense)
      end
      # --- END OF NEW TEST ---
    end

    context "with invalid params" do
      it "does not create a new Message" do
        expect {
          post :create, params: { conversation_id: conversation.id, message: { body: "" } }
        }.to_not change(Message, :count)
      end

      it "renders the 'conversations/show' template" do
        post :create, params: { conversation_id: conversation.id, message: { body: "" } }
        expect(response).to render_template("conversations/show")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when not authorized" do
      it "redirects" do
        unrelated_conversation = create(:conversation)
        post :create, params: { conversation_id: unrelated_conversation.id, message: { body: "Hi" } }
        expect(response).to redirect_to(conversations_path)
      end
    end
  end
end
