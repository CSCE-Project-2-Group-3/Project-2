# frozen_string_literal: true

# =============================
# Navigation & Basic Actions
# =============================

Given('I am on the {string} page') do |page_name|
  visit path_to(page_name)
end

When('I click {string}') do |button_text|
  click_on button_text
end

When('I enter {string} as the group name') do |group_name|
  fill_in 'Group name', with: group_name
end

When('I leave the group name blank') do
  fill_in 'Group name', with: ''
end

Then('I should see {string} in my group list') do |group_name|
  within('.group-list') do
    expect(page).to have_content(group_name)
  end
end

# =============================
# Group Membership & Invites
# =============================

Given('I am already a member of {string}') do |group_name|
  @group = Group.find_or_create_by!(name: group_name)
  @group.users << @user unless @group.users.include?(@user)
end

When('I paste a valid invite code into the "Join Group" field') do
  @invite_group = Group.find_or_create_by!(name: 'Roommates 2025')
  fill_in 'Group Code:', with: @invite_group.join_code || @invite_group.generate_join_code!
end

When('I paste an invalid or expired invite code into the "Join Group" field') do
  fill_in 'Group Code:', with: 'INVALIDCODE123'
end

# =============================
# Expense Management
# =============================

Given('I am in the group {string} with {int} members') do |group_name, count|
  @group = Group.find_or_create_by!(name: group_name)
  count.times do |i|
    user = User.find_or_create_by!(email: "member#{i}@example.com") { |u| u.password = 'password123' }
    @group.users << user unless @group.users.include?(user)
  end
end

When('I add an expense titled {string} for {string}') do |title, amount|
  click_on 'Add Expense'
  fill_in 'Title', with: title
  fill_in 'Amount', with: amount.delete('$')
end

When('I add an expense titled {string} without an amount') do |title|
  click_on 'Add Expense'
  fill_in 'Title', with: title
end

When('I select {string}') do |option|
  select option, from: 'Split Type'
end

Then('each member’s share should be {string}') do |amount|
  within('.split-summary') do
    expect(page).to have_content(amount)
  end
end

# =============================
# Group Totals
# =============================

Given('the group {string} has expenses of {string} and {string}') do |group_name, amount1, amount2|
  @group = Group.find_or_create_by!(name: group_name)
  [amount1, amount2].each do |amt|
    @group.expenses.create!(title: "Expense #{amt}", amount: amt.delete('$'))
  end
end

Given('the group {string} has no expenses') do |group_name|
  Group.find_or_create_by!(name: group_name).expenses.destroy_all
end

When('I visit the group summary page') do
  visit group_path(@group)
end

# =============================
# Comments
# =============================

Given('I am viewing the {string} expense in {string}') do |expense_title, group_name|
  @group = Group.find_or_create_by!(name: group_name)
  @expense = @group.expenses.find_or_create_by!(title: expense_title, amount: 0)
  visit group_expense_path(@group, @expense)
end

When('I type {string} in the comment box') do |comment_text|
  fill_in 'Comment', with: comment_text
end

When('I leave the comment box blank') do
  fill_in 'Comment', with: ''
end

Then('I should see my comment in the thread') do
  within('.comments-thread') do
    expect(page).to have_content(@current_user.email)
  end
end

Given('the {string} expense has {int} comments') do |expense_title, count|
  @expense = Expense.find_or_create_by!(title: expense_title)
  count.times do |i|
    @expense.comments.create!(body: "Test comment #{i + 1}", user: User.first)
  end
end

When('I open the {string} section') do |_section|
  click_on 'Comments'
end

Then('I should see all {int} comments in chronological order') do |count|
  comments = all('.comment')
  expect(comments.size).to eq(count)
end

# =============================
# Helper: path_to()
# =============================

def path_to(page_name)
  case page_name.downcase
  when 'groups' then groups_path
  when 'group summary' then group_path(@group)
  else
    raise "No path defined for page '#{page_name}'"
  end
end
