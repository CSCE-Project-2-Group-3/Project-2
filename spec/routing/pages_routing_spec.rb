require 'rails_helper'

RSpec.describe 'Routes', type: :routing do
  describe 'Pages routes' do
    it 'routes root to pages#home' do
      expect(get: '/').to route_to('pages#home')
    end

    # Remove this test as there's no /pages/home route
    # Only root path is defined for pages#home
  end

  describe 'Devise routes' do
    it 'routes to user sessions' do
      expect(get: '/users/sign_in').to route_to('users/sessions#new')
    end

    it 'routes to user registrations' do
      expect(get: '/users/sign_up').to route_to('users/registrations#new')
    end

    it 'routes to omniauth callbacks' do
      expect(post: '/users/auth/google_oauth2').to route_to('users/omniauth_callbacks#passthru')
    end
  end
end
