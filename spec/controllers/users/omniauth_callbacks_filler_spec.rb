# spec/controllers/users/omniauth_callbacks_filler_spec.rb
require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  it 'redirects properly when user is not persisted' do
    @request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: 'temp123',
      info: { email: 'tempuser@example.com' }
    )

    get :google_oauth2
    expect(response).to have_http_status(:redirect)
  end
end
