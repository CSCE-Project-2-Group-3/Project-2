require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'devise modules' do
    it 'has email column' do
      expect(User.column_names).to include('email')
      expect(User.columns_hash['email'].type).to eq(:string)
    end

    it 'has encrypted_password column' do
      expect(User.column_names).to include('encrypted_password')
      expect(User.columns_hash['encrypted_password'].type).to eq(:string)
    end

    it 'has reset_password_token column' do
      expect(User.column_names).to include('reset_password_token')
      expect(User.columns_hash['reset_password_token'].type).to eq(:string)
    end

    it 'has remember_created_at column' do
      expect(User.column_names).to include('remember_created_at')
      expect(User.columns_hash['remember_created_at'].type).to eq(:datetime)
    end
  end

  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: '123456',
        info: {
          email: 'test@example.com',
          name: 'Test User',
          image: 'http://example.com/avatar.jpg'
        }
      )
    end

    context 'when user does not exist' do
      it 'creates a new user' do
        expect {
          User.from_omniauth(auth)
        }.to change(User, :count).by(1)
      end

      it 'sets user attributes from auth data' do
        user = User.from_omniauth(auth)
        expect(user.email).to eq('test@example.com')
        expect(user.full_name).to eq('Test User')
        expect(user.avatar_url).to eq('http://example.com/avatar.jpg')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456')
      end

      it 'generates a password for the user' do
        user = User.from_omniauth(auth)
        expect(user.encrypted_password).not_to be_blank
      end
    end

    context 'when user already exists' do
      let!(:existing_user) do
        create(:user, email: 'test@example.com', provider: 'google_oauth2', uid: '123456')
      end

      it 'returns the existing user' do
        user = User.from_omniauth(auth)
        expect(user).to eq(existing_user)
      end

      it 'does not create a new user' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end
    end
  end

  describe 'omniauthable' do
    it 'includes omniauth modules' do
      expect(User.devise_modules).to include(:omniauthable)
    end

    it 'has google_oauth2 as omniauth provider' do
      expect(User.omniauth_providers).to include(:google_oauth2)
    end
  end
end
