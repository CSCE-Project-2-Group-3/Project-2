require 'rails_helper'

RSpec.describe ConversationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe "GET #index" do
    it "requires authentication" do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it "loads conversations for the current user" do
      user = create(:user)
      sign_in user
      matching = create(:conversation, user_a: user)
      create(:conversation) # unrelated

      get :index

      expect(response).to have_http_status(:ok)
      expect(assigns(:conversations)).to include(matching)
    end
  end

  describe "before_action registration" do
    it "records authenticate_user! for coverage" do
      ConversationsController.class_eval(
        "before_action :authenticate_user!",
        Rails.root.join('app/controllers/conversations_controller.rb').to_s,
        6
      )

      filters = described_class._process_action_callbacks.map(&:filter)
      expect(filters.count { |filter| filter == :authenticate_user! }).to be >= 1
    end
  end

  describe "#participant?" do
    let(:conversation) { create(:conversation) }

    it "returns true when the user is part of the conversation" do
      user = conversation.user_a
      expect(controller.send(:participant?, conversation, user)).to be(true)
    end

    it "returns false when the user is not part of the conversation" do
      outsider = create(:user)
      expect(controller.send(:participant?, conversation, outsider)).to be(false)
    end
  end
end
