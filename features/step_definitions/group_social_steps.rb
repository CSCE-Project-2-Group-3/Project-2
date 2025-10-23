# frozen_string_literal: true

Given('I am on the {string} page') do |page_name|
  visit path_to(page_name)
end

When('I click {string}') do |text|
  click_on text, exact: false
end

When('I enter {string} as the group name') do |group_name|
  fill_in 'Group name', with: group_name
end

When('I leave the group name blank') do
  fill_in 'Group name', with: ''
end

Then('I should see {string} in my group list') do |group_name|
  expect(page).to have_css('.group-list', text: group_name)
end

Given('I am already a member of {string}') do |group_name|
  @group = Group.find_or_create_by!(name: group_name)
  GroupMembership.find_or_create_by!(group: @group, user: @user)
end

When('I paste a valid invite code into the "Join Group" field') do
  @invite_group = Group.find_or_create_by!(name: 'Roommates 2025')
  fill_in 'Group Code:', with: @invite_group.join_code || @invite_group.generate_join_code!
end

When('I paste an invalid or expired invite code into the "Join Group" field') do
  fill_in 'Group Code:', with: 'INVALIDCODE123'
end

Given('I am in the group {string} with {int} members') do |group_name, count|
  @group = Group.find_or_create_by!(name: group_name)
  GroupMembership.find_or_create_by!(group: @group, user: @user)

  while @group.users.count < count
    member = FactoryBot.create(:user)
    GroupMembership.find_or_create_by!(group: @group, user: member)
  end

  visit group_path(@group)
end

When('I add an expense titled {string} for {string}') do |title, amount|
  category = Category.first || FactoryBot.create(:category, name: "Default Category")
  click_on 'Add', exact: false
  fill_in 'Title', with: title
  fill_in 'Amount', with: amount.delete('$')
  fill_in 'Spent on', with: Date.today
  select category.name, from: 'Category'
end

When('I choose to split the bill with all group members') do
  all('input[type="checkbox"][name="expense[participant_ids][]"]', visible: :all).each do |checkbox|
    checkbox.set(true) unless checkbox.checked?
  end
end

Then('each member’s share should be {string}') do |amount|
  expense = Expense.order(created_at: :desc).first
  names = expense.participants.map { |user| user.full_name.presence || user.email }.join(', ')
  formatted_amount = ActionController::Base.helpers.number_to_currency(amount.delete('$').to_f)
  expect(page).to have_content("#{formatted_amount}: #{names}")
end

Given('the group {string} has expenses of {string} and {string}') do |group_name, amount1, amount2|
  @group = Group.find_or_create_by!(name: group_name)
  GroupMembership.find_or_create_by!(group: @group, user: @user)
  category = Category.first || FactoryBot.create(:category)
  [amount1, amount2].each do |amt|
    @group.expenses.create!(title: "Expense #{amt}", amount: amt.delete('$'), spent_on: Date.today, category: category, user: @user)
  end
end

Given('the group {string} has no expenses') do |group_name|
  @group = Group.find_or_create_by!(name: group_name)
  @group.expenses.destroy_all
end

When('I visit the group summary page') do
  visit group_path(@group)
end

Given('I am viewing the {string} expense in {string}') do |expense_title, group_name|
  @group = Group.find_or_create_by!(name: group_name)
  GroupMembership.find_or_create_by!(group: @group, user: @user)
  category = Category.first || FactoryBot.create(:category)
  @expense = @group.expenses.find_or_create_by!(title: expense_title) do |expense|
    expense.amount = 0
    expense.spent_on = Date.today
    expense.category = category
    expense.user = @user
  end
  visit group_path(@group)
end

When('I type {string} in the comment box') do |comment_text|
  fill_in 'Comment', with: comment_text
end

When('I leave the comment box blank') do
  fill_in 'Comment', with: ''
end

Then('I should see my comment in the thread') do
  expect(page).to have_css('.comments-thread', text: @user.email)
end

Given('the {string} expense has {int} comments') do |expense_title, count|
  category = Category.first || FactoryBot.create(:category)
  @expense = Expense.find_or_create_by!(title: expense_title) do |expense|
    expense.amount = 0
    expense.spent_on = Date.today
    expense.category = category
    expense.user = @user || FactoryBot.create(:user)
  end

  count.times do |i|
    @expense.comments.create!(body: "Test comment #{i + 1}", user: @user || FactoryBot.create(:user))
  end
end

When('I open the {string} section') do |_section|
  click_on 'Comments'
end

Then('I should see all {int} comments in chronological order') do |count|
  expect(all('.comment').size).to eq(count)
end

def path_to(page_name)
  case page_name.downcase
  when 'groups' then groups_path
  when 'group summary' then group_path(@group)
  when 'new expenses' then new_expense_path
  else
    raise "No path defined for page '#{page_name}'"
  end
end
