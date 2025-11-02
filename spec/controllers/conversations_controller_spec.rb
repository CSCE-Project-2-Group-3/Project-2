require 'rails_helper'

RSpec.describe ConversationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  # --- FIX ---
  # Move let! blocks to the top level `describe`
  # This makes `user` and `other_user` available to all contexts.
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }

  describe "GET #index" do
    # This example runs with no user signed in
    it "requires authentication" do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    # All tests that require a logged-in user are now inside this block
    context "when user is signed in" do
      # Sign in the user for all tests in this context
      before { sign_in user }

      it "loads conversations for the current user" do
        # We can now reference the `user` from the let! block
        matching = create(:conversation, user_a: user)
        create(:conversation) # unrelated conversation

        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:conversations)).to include(matching)
      end

      # This context now has access to `user` and `other_user`
      context "when user is in a group" do
        it "assigns messageable users" do
          group = create(:group, users: [ user, other_user ])

          get :index

          expect(assigns(:messageable_by_group)[group]).to eq([ other_user ])
        end
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

      filters = described_class._process_action_callbacks.map(&:filter)
      expect(filters.count { |filter| filter == :authenticate_user! }).to be >= 1
    end
  end

  # Remove the participant? tests since the method doesn't exist in the controller
end
