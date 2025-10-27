Feature: Dashboard Page
  As a logged-in user
  I want to see my dashboard with summaries, charts, and filters
  So I can understand my spending habits.

  Background:
    Given I am a registered user and I am logged in
    And I have a "Food" expense "Groceries" with amount $150
    And I have a "Transport" expense "Gas" with amount $60
    And I have a "Housing" group expense "Rent" with amount $800

  Scenario: Viewing dashboard summaries
    When I go to the dashboard page
    Then I should see "Your Dashboard"
    
    # Check Personal Expenses
    And I should see "Total Spent: $210.00"
    And I should see "Groceries" in the "Recent Personal Expenses" list
    And I should see "Gas" in the "Recent Personal Expenses" list
    
    # Check Group Expenses
    And I should see "Total Spent (in groups): $800.00"
    And I should see "Rent" in the "Recent Group Expenses" list

  Scenario: Filtering the dashboard
    When I go to the dashboard page
    # Totals should include everything at first
    Then I should see "Total Spent: $210.00"

    # Now, filter by category
    When I select "Food" from the "Category" dropdown
    And I click the "Filter" button
    
    # Totals should update
    Then I should see "Total Spent: $150.00"
    # The group total is unaffected by this filter
    And I should see "Total Spent (in groups): $800.00"

    # The list should update
    And I should see "Groceries" in the "Recent Personal Expenses" list
    And I should not see "Gas" in the "Recent Personal Expenses" list

  Scenario: Viewing AI summary and charts
    # We must stub the AI call to avoid real API requests
    Given I have stubbed the AI summary to return "This is a test summary."
    When I go to the dashboard page
    
    # Check for AI Summary
    Then I should see "🤖 Your AI Spending Summary"
    And I should see "This is a test summary."

    # Check that the charts are on the page
    # We don't test the chart image, just that the container is there.
    And I should see the "Personal Spending by Category" chart
    And I should see the "Spending Over Time" chart
    