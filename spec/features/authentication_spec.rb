require 'rails_helper'

RSpec.describe 'Authentication', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  describe 'Sign in' do
    it 'allows user to sign in with email and password' do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      # Check for successful redirect
      expect(page).to have_current_path(root_path)
    end

    it 'shows error with invalid credentials' do
      visit new_user_session_path
      fill_in 'Email', with: 'wrong@example.com'
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Log in'
      # Check for any error indication
      expect(page).to have_content('Invalid Email or password').or have_content('Invalid')
    end
  end

  describe 'Sign up' do
    it 'allows new user to sign up' do
      visit new_user_registration_path
      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      click_button 'Sign up'
      # Check for successful redirect
      expect(page).to have_current_path(root_path)
    end
  end

  describe 'Sign out' do
    before do
      # Use direct login via form
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      visit root_path
    end

    it 'allows user to sign out' do
      # Look for logout link or button
      logout_element = first('a[href*="sign_out"], a[href*="logout"], button', text: /Logout|Sign out/i)

      if logout_element
        logout_element.click
        expect(page).to have_content('Login').or have_content('Sign in')
        expect(page).to have_content('Create Account').or have_content('Sign up')
      else
        # If no logout element found, the test should fail
        expect(page).to have_css('a[href*="sign_out"], a[href*="logout"], button', text: /Logout|Sign out/i)
      end
    end
  end
end
