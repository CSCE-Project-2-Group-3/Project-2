Feature: Add an expense
  In order to track my spending
  As a user
  I want to add a new expense with a category

  Scenario: Successfully adding an expense
    Given I am logged in
    And I am on the "new expenses" page
    When I fill in the expense field "Title" with "Lunch"
    And I fill in the expense field "Amount" with "10.50"
    And I fill in the expense field "Spent on" with "2025-10-18"
    And I select "Food" from the expense dropdown "Category"
    And I click on "Save Expense"
    Then I should see the expense message "Expense added successfully."

  Scenario: Create a group expense
    Given a group exists with name "Roommates"
    When I go to the new expense page for group "Roommates"
    And I fill in the expense field "Title" with "Lunch"
    And I fill in the expense field "Amount" with "10.50"
    And I fill in the expense field "Spent on" with "2025-10-18"
    And I select "Food" from the expense dropdown "Category"
    And I click on "Save Expense"
    Then I should be on the group page for "Roommates"
    And I should see "Expense created!"