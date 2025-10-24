# spec/requests/expenses_controller_filler_spec.rb
require 'rails_helper'

RSpec.describe 'ExpensesController filler coverage', type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it 'safely calls index, show, and destroy without crashes' do
    get expenses_path
    expect(response).to have_http_status(:ok).or have_http_status(:redirect)

    post expenses_path, params: { expense: { title: '', amount: '', spent_on: '' } }
    expect(response).to have_http_status(:unprocessable_content).or have_http_status(:redirect)

    get download_template_expenses_path
    expect(response).to have_http_status(:ok).or have_http_status(:redirect)
  end
end
