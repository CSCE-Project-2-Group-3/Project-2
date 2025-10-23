# features/step_definitions/expenses_step.rb
Given('I have a category called {string}') do |name|
  Category.find_or_create_by!(name: name)
end

Given('a group exists with name {string}') do |name|
  Group.find_or_create_by!(name: name)
end

When('I go to the new expense page') do
  visit new_expense_path
end

When('I go to the new expense page for group {string}') do |group_name|
  group = Group.find_by(name: group_name)
  visit new_group_expense_path(group)
end

When('I go to the expenses index page') do
  visit expenses_path
end

When('I fill in the expense field {string} with {string}') do |field, value|
  fill_in field, with: value, match: :first
rescue Capybara::ElementNotFound
  fill_in "expense_#{field.downcase.gsub(' ', '_')}", with: value
end

When('I select {string} from the expense dropdown {string}') do |option, field|
  category = Category.find_or_create_by!(name: option)
  visit current_path
  select category.name, from: field
end


When('I press the expense button {string}') do |button|
  click_button button
end

When('I attach the expense file {string} to {string}') do |file, field|
  attach_file field, file
end

When('I select a category') do
  category = Category.first || FactoryBot.create(:category, name: "Default Category")
  select category.name, from: "Category"
end

Then('I should see the expense message {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should be on the group page for {string}') do |group_name|
  group = Group.find_by(name: group_name)
  expect(page).to have_current_path(group_path(group))
end
