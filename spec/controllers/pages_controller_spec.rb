require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  # We need Devise test helpers to sign in our user
  include Devise::Test::ControllerHelpers

  # --- Tests for GET #home (Your existing code) ---
  describe 'GET #home' do
    context 'when user is not signed in' do
      it 'returns http success' do
        get :home
        expect(response).to have_http_status(:success)
      end

      it 'renders the home template' do
        get :home
        # Using render_template is more specific than be_successful
        expect(response).to render_template(:home)
      end
    end

    context 'when user is signed in' do
      # Assumes you have a :user factory defined
      let(:user) { create(:user) }

      before { sign_in user }

      it 'returns http success' do
        get :home
        expect(response).to have_http_status(:success)
      end

      it 'renders the home template' do
        get :home
        expect(response).to render_template(:home)
      end
    end
  end

  # --- Tests for GET #dashboard (Newly added) ---
  describe "GET #dashboard" do
    # Assumes you have factories for :user, :category, and :group
    let!(:user) { create(:user) }
    let!(:food_category) { create(:category, name: 'Food') }
    let!(:rent_category) { create(:category, name: 'Housing') }
    let!(:group) { create(:group, name: 'Roommates', users: [ user ]) }

    context "when user is not logged in" do
      it "redirects to the login page" do
        get :dashboard
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is logged in" do
      before do
        # Assumes you have an :expense factory
        create(:expense,
          title: 'Groceries',
          amount: 150,
          spent_on: Date.today,
          category: food_category,
          user: user
        )

        create(:expense,
          title: 'Rent',
          amount: 800,
          spent_on: Date.today,
          category: rent_category,
          user: user,
          group: group
        )

        # Stub the private method 'get_ai_summary' to avoid API calls
        allow(controller).to receive(:get_ai_summary).and_return("Mock AI Summary")

        # Sign in the user
        sign_in user

        # Make the request
        get :dashboard
      end

      it "returns a successful (200 OK) response" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the dashboard template" do
        expect(response).to render_template(:dashboard)
      end

      it "assigns the correct personal total" do
        expect(assigns(:personal_total)).to eq(150)
      end

      it "assigns the correct group total" do
        expect(assigns(:group_total)).to eq(800)
      end

      it "assigns the recent personal expenses" do
        expect(assigns(:recent_personal_expenses).first.title).to eq('Groceries')
      end

      it "assigns the recent group expenses" do
        expect(assigns(:recent_group_expenses).first.title).to eq('Rent')
      end

      it "assigns the categories for the filter" do
        expect(assigns(:categories)).to include(food_category, rent_category)
      end

      it "assigns the (mocked) AI summary" do
        expect(assigns(:ai_summary)).to eq("Mock AI Summary")
      end

      it "assigns the data for the category pie chart" do
        # --- FIX ---
        # The charts now correctly *only* show personal expenses.
        # The test is updated to expect only the "Food" category.
        expect(assigns(:category_labels)).to match_array([ "Food" ])
        expect(assigns(:category_data)).to match_array([ 150 ])
      end
    end

    context "when filters are provided" do
      let!(:filtered_category) { create(:category, name: 'Filtered') }
      let!(:other_category) { create(:category, name: 'Other') }

      before do
        sign_in user
        create(:expense,
               title: 'Within Range',
               amount: 45,
               spent_on: Date.today,
               category: filtered_category,
               user: user)
        create(:expense,
               title: 'Outside Category',
               amount: 20,
               spent_on: Date.today,
               category: other_category,
               user: user)
        create(:expense,
               title: 'Outside Date Range',
               amount: 99,
               spent_on: 10.days.ago,
               category: filtered_category,
               user: user)

        allow(controller).to receive(:get_ai_summary).and_return("Filtered Summary")
        get :dashboard, params: {
          category_id: filtered_category.id,
          start_date: 2.days.ago.to_date.to_s,
          end_date: Date.today.to_s
        }
      end

      it "applies category and date filters to personal expenses" do
        expect(assigns(:recent_personal_expenses).map(&:title)).to eq([ 'Within Range' ])
      end

      it "filters the spending over time data" do
        # This checks the bar chart data. The `compact` removes nils, `values` gets the amounts.
        # It finds 45 (Within Range) but not 20 (Outside Category) or 99 (Outside Date).
        expect(assigns(:spending_over_time).compact.values).to contain_exactly(45)
      end
    end

    context "when no personal expenses exist" do
      before do
        sign_in user
        # create a group expense so total_spending isn't 0
        create(:expense, user: user, group: group, category: rent_category, amount: 10)
        get :dashboard
      end

      it "returns the AI summary" do
        # This test is now just checking that the AI summary is called
        expect(assigns(:ai_summary)).to_not be_nil
      end
    end

    context "when an AI summary is pre-stubbed" do
      before do
        PagesController.class_variable_set(:@@stubbed_ai_summary, "Prebaked insight")
        sign_in user
        create(:expense,
               title: 'Lunch',
               amount: 12,
               spent_on: Date.today,
               category: create(:category),
               user: user)
        get :dashboard
      end

      after do
        if PagesController.class_variable_defined?(:@@stubbed_ai_summary)
          PagesController.remove_class_variable(:@@stubbed_ai_summary)
        end
      end

      it "uses the stubbed AI summary without calling the API" do
        expect(assigns(:ai_summary)).to eq("Prebaked insight")
      end
    end

    context "when the AI summary API responds successfully" do
      let(:client) { instance_double(OpenAI::Client) }

      before do
        sign_in user
        create(:expense,
               title: 'Dinner',
               amount: 33,
               spent_on: Date.today,
               category: create(:category),
               user: user)
        allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("fake-token")
        allow(OpenAI::Client).to receive(:new).with(access_token: "fake-token").and_return(client)
        allow(client).to receive(:chat).with(hash_including(:parameters)).and_return(
          { "choices" => [ { "message" => { "content" => "AI says hello" } } ] }
        )
        get :dashboard
      end

      it "assigns the AI response to the summary" do
        expect(assigns(:ai_summary)).to eq("AI says hello")
      end
    end

    context "when the AI summary API raises an error" do
      let(:client) { instance_double(OpenAI::Client) }

      before do
        sign_in user
        create(:expense,
               title: 'Snacks',
               amount: 10,
               spent_on: Date.today,
               category: create(:category),
               user: user)
        allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("fake-token")
        allow(OpenAI::Client).to receive(:new).with(access_token: "fake-token").and_return(client)
        allow(client).to receive(:chat).and_raise(StandardError.new("boom"))
        allow(Rails.logger).to receive(:error)
        get :dashboard
      end

      it "falls back to a friendly placeholder summary" do
        expect(assigns(:ai_summary)).to eq("Your AI summary is being generated. Check back soon!")
      end

      it "logs the error for visibility" do
        expect(Rails.logger).to have_received(:error).with(/AI Summary Failed: boom/)
      end
    end
  end
end
