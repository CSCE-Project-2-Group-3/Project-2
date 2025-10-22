# spec/requests/users_passwords_request_spec.rb
require 'rails_helper'

RSpec.describe 'Users::PasswordsController', type: :request do
  it 'renders the new password reset page successfully' do
    get new_user_password_path
    expect(response).to have_http_status(:ok)

    # Be flexible about wording across Devise templates/locales
    expect(response.body).to match(
      /(Forgot.*password|Reset.*password|Send.*reset.*instructions|Email)/i
    )
  end
end
