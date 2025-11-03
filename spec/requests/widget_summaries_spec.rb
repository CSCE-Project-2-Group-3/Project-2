require 'rails_helper'

RSpec.describe "WidgetSummaries", type: :request do
  # We need Devise test helpers to sign in our user
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) } # Assumes you have a :user factory

  describe "GET /show" do
    it "returns http success when user is signed in" do
      sign_in user # <--- THIS IS THE FIX

      get widget_summary_path(widget: "personal_expenses")
      expect(response).to have_http_status(:success)
    end

    it "redirects when user is not signed in" do
      get widget_summary_path(widget: "personal_expenses")
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /empty" do
    it "returns http success" do
      get empty_modal_path
      expect(response).to have_http_status(:success)
    end
  end
end
