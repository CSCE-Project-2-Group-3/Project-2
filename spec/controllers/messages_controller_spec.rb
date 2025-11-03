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

      it "creates a message with quoted expenses" do
        expense1 = create(:expense, user: other_user)
        expense2 = create(:expense, user: other_user)

        expect do
          post :create, params: {
            conversation_id: conversation.id,
            message: {
              body: "Check out these expenses",
              quoted_expense_ids: [ expense1.id, expense2.id ]
            }
          }
        end.to change(Message, :count).by(1)

        expect(response).to redirect_to(conversation_path(conversation, anchor: "message-#{Message.last.id}"))

        message = Message.last
        expect(message.quoted_expenses).to contain_exactly(expense1, expense2)
        expect(conversation.reload.updated_at).to be_within(1.second).of(Time.current)
      end

      it "attaches quoted expenses if provided" do
        expense = create(:expense, user: user)
        post :create, params: {
          conversation_id: conversation.id,
          message: {
            body: "Check this expense",
            quoted_expense_ids: [ expense.id ]
          }
        }

        expect(Message.last.quoted_expenses).to include(expense)
      end

      it "creates a message without quoted expenses" do
        expect do
          post :create, params: {
            conversation_id: conversation.id,
            message: {
              body: "Simple message"
            }
          }
        end.to change(Message, :count).by(1)

        expect(response).to redirect_to(conversation_path(conversation, anchor: "message-#{Message.last.id}"))

        message = Message.last
        expect(message.quoted_expenses).to be_empty
      end

      it "creates a message with empty quoted expense ids" do
        expect do
          post :create, params: {
            conversation_id: conversation.id,
            message: {
              body: "Message with empty expense ids",
              quoted_expense_ids: []
            }
          }
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.quoted_expenses).to be_empty
      end
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

      it "renders conversations/show when message fails to save" do
        expect do
          post :create, params: {
            conversation_id: conversation.id,
            message: {
              body: "" # Invalid - empty body
            }
          }
        end.not_to change(Message, :count)

        expect(response).to render_template("conversations/show")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:messages)).to eq(conversation.messages.includes(:user, :quoted_expenses))
        expect(assigns(:other_user)).to eq(other_user)
        expect(assigns(:expenses)).not_to be_nil
      end
    end

    context "when not authorized" do
      it "redirects to conversations path with alert" do
        other_conversation = create(:conversation) # Conversation user is not part of

        post :create, params: {
          conversation_id: other_conversation.id,
          message: {
            body: "Unauthorized message"
          }
        }

        expect(response).to redirect_to(conversations_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end
  end

  context "when not authenticated" do
    it "requires authentication" do
      sign_out user # Ensure no user is signed in

      post :create, params: {
        conversation_id: conversation.id,
        message: { body: "Test message" }
      }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end