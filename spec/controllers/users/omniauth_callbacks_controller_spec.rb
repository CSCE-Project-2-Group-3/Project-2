require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    @request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '12345',
      info: { email: 'omniauth@example.com' }
    )
  end

  describe 'GET #google_oauth2' do
    it 'signs in an existing user' do
      user = create(:user, email: 'omniauth@example.com', provider: 'google_oauth2', uid: '12345')

      expect do
        get :google_oauth2
      end.not_to change(User, :count)

      expect(response).to redirect_to(expenses_path)
      expect(controller.current_user).to be_present
      expect(controller.current_user.email).to eq(user.email)
    end

    it 'creates a new user if not found' do
      expect do
        get :google_oauth2
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(expenses_path)
      expect(controller.current_user).to be_present
    end

    it 'redirects to fallback path on failure' do
      get :google_oauth2, params: {}, session: { 'devise.omniauth_data' => nil }
      expect(response).to redirect_to(expenses_path)
    end
  end
end
