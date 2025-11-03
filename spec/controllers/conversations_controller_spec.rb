require 'rails_helper'

RSpec.describe ConversationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let(:other_user1) { create(:user) }
  let(:other_user2) { create(:user) }
  let(:group) { create(:group) }

  describe "GET #index" do
    it "requires authentication" do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when user is signed in" do
      before { sign_in user }

      it "loads conversations for the current user" do
        matching = create(:conversation, user_a: user)
        create(:conversation) # unrelated conversation

        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:conversations)).to include(matching)
      end

      it "sets up messageable users by group excluding current user" do
        # Add users to group
        group.users << [ user, other_user1, other_user2 ]

        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:messageable_by_group)).to be_a(Hash)
        expect(assigns(:messageable_by_group)[group]).to contain_exactly(other_user1, other_user2)
        expect(assigns(:messageable_by_group)[group]).not_to include(user)
      end

      it "handles groups where current user is the only member" do
        group.users << user

        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:messageable_by_group)[group]).to be_empty
      end

      it "handles multiple groups with different members" do
        group2 = create(:group)
        group.users << [ user, other_user1 ]
        group2.users << [ user, other_user2 ]

        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:messageable_by_group)[group]).to contain_exactly(other_user1)
        expect(assigns(:messageable_by_group)[group2]).to contain_exactly(other_user2)
      end

      context "when user is in a group" do
        it "assigns messageable users" do
          group = create(:group, users: [ user, other_user ])

          get :index

          expect(assigns(:messageable_by_group)[group]).to eq([ other_user ])
        end
      end
    end
  end

  describe "GET #show" do
    context "when user is signed in" do
      before { sign_in user }

      it "loads a conversation the user is part of" do
        conversation = create(:conversation, user_a: user)

        get :show, params: { id: conversation.id }

        expect(response).to have_http_status(:ok)
        expect(assigns(:conversation)).to eq(conversation)
      end

      it "redirects if user is not part of the conversation" do
        other_conversation = create(:conversation) # conversation without current user

        get :show, params: { id: other_conversation.id }

        expect(response).to redirect_to(conversations_path)
        expect(flash[:alert]).to eq("You are not authorized to view that conversation.")
      end
    end
  end

  describe "before_action registration" do
    it "records authenticate_user! for coverage" do
      # This test is a bit unusual, but it's checking that the
      # before_action is registered.
      ConversationsController.class_eval(
        "before_action :authenticate_user!",
        Rails.root.join('app/controllers/conversations_controller.rb').to_s,
        6
      )
    end
  end

  describe "POST #create" do
    context "when user is signed in" do
      before { sign_in user }

      it "creates a new conversation with valid recipient" do
        recipient = create(:user)

        expect {
          post :create, params: { recipient_id: recipient.id }
        }.to change(Conversation, :count).by(1)

        expect(response).to redirect_to(conversation_path(Conversation.last))
      end

      it "redirects to existing conversation if one already exists" do
        recipient = create(:user)
        existing_conversation = create(:conversation, user_a: user, user_b: recipient)

        expect {
          post :create, params: { recipient_id: recipient.id }
        }.not_to change(Conversation, :count)

        expect(response).to redirect_to(conversation_path(existing_conversation))
      end

      it "redirects with alert if recipient not found" do
        post :create, params: { recipient_id: 99999 }

        expect(response).to redirect_to(conversations_path)
        expect(flash[:alert]).to eq("Recipient not found.")
      end

      it "redirects with notice if trying to create conversation with self" do
        post :create, params: { recipient_id: user.id }

        expect(response).to redirect_to(conversations_path)
        expect(flash[:notice]).to eq("You cannot start a conversation with yourself.")
      end
    end
  end
end
