# spec/requests/devise_controllers_smoke_spec.rb
require 'rails_helper'

RSpec.describe 'Devise controllers smoke tests', type: :request do
  it 'renders login page' do
    get new_user_session_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Log in').or include('Login')
  end

  it 'renders sign up page' do
    get new_user_registration_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Sign up').or include('Create Account')
  end
end
