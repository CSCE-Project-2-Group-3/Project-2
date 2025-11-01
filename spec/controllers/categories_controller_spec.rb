require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #new' do
    it 'renders the new category page' do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new category and redirects' do
        expect {
          post :create, params: { category: { name: 'Snacks' } }
        }.to change(Category, :count).by(1)
        expect(response).to redirect_to(new_expense_path)
        expect(flash[:notice]).to eq('Category created successfully.')
      end
    end

    context 'with invalid parameters' do
      it 'does not create with blank name and re-renders new' do
        expect {
          post :create, params: { category: { name: '' } }
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create with duplicate name and re-renders new' do
        create(:category, name: 'Existing Category')

        expect {
          post :create, params: { category: { name: 'Existing Category' } }
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
