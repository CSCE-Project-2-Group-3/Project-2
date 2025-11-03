require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Test the methods directly using a concrete controller instance
  controller(ApplicationController) do
    def index
      render plain: 'test'
    end
  end

  let(:user) { create(:user) }

  describe '#after_sign_in_path_for' do
    it 'returns expenses_path after sign in' do
      expect(controller.after_sign_in_path_for(user)).to eq('/expenses')
    end
  end

  describe '#after_sign_out_path_for' do
    it 'returns new_user_session_path after sign out' do
      expect(controller.after_sign_out_path_for(:user)).to eq('/users/sign_in')
    end
  end

  describe '#not_found' do
    context 'when user is signed in' do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:redirect_to)
      end

      it 'redirects to root path with alert message' do
        expect(controller).to receive(:redirect_to).with('/', alert: "Page not found")
        controller.not_found
      end
    end

    context 'when user is not signed in' do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
        allow(controller).to receive(:authenticate_user!)
      end

      it 'triggers authentication' do
        expect(controller).to receive(:authenticate_user!)
        controller.not_found
      end
    end
  end

  describe 'before_action :authenticate_user!' do
    before do
      routes.draw { get 'index' => 'anonymous#index' }
    end

    context 'when user is not signed in' do
      it 'redirects to login page for protected actions' do
        get :index
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'allows access to protected actions' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('test')
      end
    end
  end
end
