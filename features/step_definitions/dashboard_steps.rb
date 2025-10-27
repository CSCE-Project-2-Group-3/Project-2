# Combine user creation and login
Given "I am a registered user and I am logged in" do
    @user = User.create!(
      email: 'test@example.com',
      password: 'password'
    )
    login_as(@user, scope: :user)
  end

  # Step to create a personal expense with a specific category
  Given "I have a {string} expense {string} with amount ${int}" do |category_name, title, amount|
    category = Category.find_or_create_by!(name: category_name)
    @user.expenses.create!(
      title: title,
      amount: amount,
      spent_on: Date.today,
      category: category,
      group: nil
    )
  end

  # Step to create a group expense with a specific category
  Given "I have a {string} group expense {string} with amount ${int}" do |category_name, title, amount|
    category = Category.find_or_create_by!(name: category_name)
    group = @user.groups.create!(name: "Test Group")
    @user.expenses.create!(
      title: title,
      amount: amount,
      spent_on: Date.today,
      category: category,
      group: group
    )
  end

  When "I go to the dashboard page" do
    visit dashboard_path
  end

  When "I select {string} from the {string} dropdown" do |option_text, label_text|
    select(option_text, from: label_text)
  end

  Then "I should not see {string}" do |content|
    expect(page).not_to have_content(content)
  end

  # This step mocks the controller method
  Given "I have stubbed the AI summary to return {string}" do |summary_text|
    # This tells RSpec to "intercept" the 'get_ai_summary' call
    # on *any* instance of PagesController and return our text.
    allow_any_instance_of(PagesController).to receive(:get_ai_summary).and_return(summary_text)
  end

  # ADD THESE STEPS to dashboard_steps.rb

  Then('I should see {string} in the {string} list') do |content, list_header|
    # This finds the list by its header (h5) and then looks for the content inside it
    list = find("h5", text: list_header).find(:xpath, "..") # Find parent element
    expect(list).to have_content(content)
  end

  Then('I should not see {string} in the {string} list') do |content, list_header|
    list = find("h5", text: list_header).find(:xpath, "..") # Find parent element
    expect(list).not_to have_content(content)
  end

  # This step just checks for the canvas element by its ID
  Then "I should see the {string} chart" do |chart_title|
    if chart_title == "Personal Spending by Category"
      expect(page).to have_css("#categoryPieChart")
    elsif chart_title == "Spending Over Time"
      expect(page).to have_css("#spendingBarChart")
    end
  end
