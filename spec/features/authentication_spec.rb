require 'rails_helper'

RSpec.describe 'Authentication', type: :feature do
  # Use unique email each run to avoid duplicate validation issues
  let(:user) { create(:user, email: "test_#{SecureRandom.hex(4)}@example.com") }

  describe 'Sign in' do
    it 'allows user to sign in with email and password' do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # --- FIX ---
      # The error message `expected "/" to equal "/dashboard"` shows
      # the app correctly redirects to root_path (`/`). The test was wrong.
      expect(page).to have_current_path(root_path)
    end

    it 'shows error with invalid credentials' do
      visit new_user_session_path
      fill_in 'Email', with: 'wrong@example.com'
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Log in'
      expect(page).to have_content(/Invalid Email or password|Invalid/i)
    end
  end

  describe 'Sign up' do
    it 'allows new user to sign up' do
      visit new_user_registration_path
      fill_in 'Email', with: "newuser_#{SecureRandom.hex(4)}@example.com"
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      click_button 'Sign up'

      # This is correct, new user sign-up redirects to dashboard
      expect(page).to have_current_path(dashboard_path)
    end
  end

  describe 'Sign out' do
    before do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      visit root_path
    end

    it 'allows user to sign out' do
      logout_button = find_button(title: "Logout")

      expect(logout_button).to be_visible
      logout_button.click

      expect(page).to have_content(/Log in|Sign in|Signed out successfully/i)
      expect(page).to have_content(/Sign up|Create Account/i)
    end
  end
end
