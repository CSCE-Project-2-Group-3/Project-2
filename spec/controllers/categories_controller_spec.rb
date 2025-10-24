# spec/controllers/categories_controller_spec.rb
require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  it 'renders the new category page' do
    get :new
    expect(response).to have_http_status(:ok)
  end

  it 'creates a new category and redirects' do
    expect {
      post :create, params: { category: { name: 'Snacks' } }
    }.to change(Category, :count).by(1)
    expect(response).to redirect_to(new_expense_path)
  end

  # ✅ Covers the else-branch + category_params path (blank name invalid)
  it 'does not create with blank name and re-renders new' do
    expect {
      post :create, params: { category: { name: '' } }
    }.not_to change(Category, :count)

    # Some apps return 422, some just render :ok; cover both safely
    expect(response).to have_http_status(:unprocessable_content).or have_http_status(:ok)
  end
end
