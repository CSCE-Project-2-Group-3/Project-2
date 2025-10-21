Given('I have a category called {string}') do |name|
  Category.create!(name:)
end

When('I go to the new expense page') do
  visit new_expense_path
end

When('I go to the expenses index page') do
  visit expenses_path
end

When('I fill in {string} with {string}') do |field, value|
    fill_in field, with: value, match: :first
rescue Capybara::ElementNotFound
    fill_in "expense_#{field.downcase.gsub(' ', '_')}", with: value
end

When('I select {string} from {string}') do |option, field|
  select option, from: field
end

When('I press {string}') do |button|
  click_button button
end

When('I attach the file {string} to {string}') do |file, field|
  attach_file field, file
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end
