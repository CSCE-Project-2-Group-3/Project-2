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
    let!(:group) { create(:group, name: 'Roommates', users: [user]) }

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
        expect(assigns(:category_labels)).to eq(["Food"])
        expect(assigns(:category_data)).to eq([150])
      end
    end
  end
end
