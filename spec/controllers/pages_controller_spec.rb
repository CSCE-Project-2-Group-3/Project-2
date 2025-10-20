require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #home' do
    context 'when user is not signed in' do
      it 'returns http success' do
        get :home
        expect(response).to have_http_status(:success)
      end

      it 'renders the home template' do
        get :home
        expect(response).to be_successful
      end
    end

    context 'when user is signed in' do
      let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

      before do
        sign_in user
      end

      it 'returns http success' do
        get :home
        expect(response).to have_http_status(:success)
      end

      it 'renders the home template' do
        get :home
        expect(response).to be_successful
      end
    end
  end
end
