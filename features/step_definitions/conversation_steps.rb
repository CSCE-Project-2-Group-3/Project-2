# frozen_string_literal: true

Given("the following users exist:") do |table|
  table.hashes.each do |user_attrs|
    User.create!(user_attrs)
  end
end

Given("I am logged in as {string}") do |email|
  user = User.find_by!(email: email)
  warden_login_as(user, scope: :user)
end

Given("an expense posted by {string}") do |email|
  user = User.find_by!(email: email)
  @expense = Expense.create!(
    title: "Sample Expense",
    amount: 10.00,
    spent_on: Date.today,
    user: user,
    category: Category.first_or_create!(name: "General")
  )
end

When("I visit that expense page") do
  visit expense_path(@expense)
end

When("I click the message button {string}") do |button|
  click_on button
end

Then("I should be on the conversation page with {string}") do |recipient_name|
  expect(page).to have_content("Conversation with #{recipient_name}")
end

Then("I should see the conversation text {string}") do |text|
  expect(page).to have_content(text)
end

# Updated unique names for generic lookups
Then("I should see in conversation {string}") do |text|
  expect(page).to have_content(text)
end

Given("a conversation between {string} and {string}") do |email1, email2|
  user1 = User.find_by!(email: email1)
  user2 = User.find_by!(email: email2)
  @conversation = Conversation.find_or_create_between(user1, user2)
  warden_login_as(user1, scope: :user)
end

When("I send a message saying {string}") do |body|
  visit conversation_path(@conversation)
  fill_in "message_body", with: body
  click_on "Send"
end


Then("Bob should see the same message when he logs in") do
  bob = User.find_by!(email: "bob@example.com")
  logout(:user)
  warden_login_as(bob, scope: :user)
  visit conversation_path(@conversation)
  expect(page).to have_content("Hi Bob!")
end
