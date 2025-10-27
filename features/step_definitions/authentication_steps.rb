Given("I am not logged in") do
  # Simply ensure we're on a neutral page - don't try to visit sign_out if it doesn't exist
  visit root_path
end

Given("I am logged in") do
  @user = User.find_or_create_by!(email: 'test@example.com') do |u|
    u.password = 'password123'
  end

  logout(:user) rescue nil  # ensure clean session
  visit new_user_session_path

  fill_in 'user_email', with: @user.email
  fill_in 'user_password', with: 'password123'
  click_button 'Log in'
end



Given("a user exists with email {string} and password {string}") do |email, password|
  User.create!(email: email, password: password)
end

When("I am on the home page") do
  visit root_path
end

When("I click on {string}") do |link_text|
  click_link link_text
end

When("I click the {string} button") do |button_text|
  click_button button_text
end

When("I click on {string} with class {string}") do |link_text, link_class|
  find('a', text: link_text, class: link_class).click
end

When("I fill in {string} with {string}") do |field, value|
  fill_in field, with: value
end

When("I fill in password fields with {string}") do |password|
  fill_in "Password", with: password
  fill_in "Password confirmation", with: password
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should not see {string}") do |text|
  expect(page).not_to have_content(text)
end

Then("I should be on the registration page") do
  expect(current_path).to eq(new_user_registration_path)
end

Then("I should be on the login page") do
  expect(current_path).to eq(new_user_session_path)
end
