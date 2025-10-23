Feature: Add an expense
  In order to track my spending
  As a user
  I want to add a new expense with a category

  Scenario: Successfully adding an expense
    Given I am logged in
    And I have a category called "Food"
    And I am on the "new expenses" page
    When I select "Food" from the expense dropdown "Category"
    And I fill in the expense field "Title" with "Lunch"
    And I fill in the expense field "Amount" with "10.50"
    And I fill in the expense field "Spent on" with "2025-10-18"
    And I press the expense button "Save Expense"
    Then I should see the expense message "Expense created!"

  Scenario: Create a group expense
    Given I am logged in
    And I am already a member of "Roommates"
    And I have a category called "Food"
    When I go to the new expense page for group "Roommates"
    And I select "Food" from the expense dropdown "Category"
    And I fill in the expense field "Title" with "Lunch"
    And I fill in the expense field "Amount" with "10.50"
    And I fill in the expense field "Spent on" with "2025-10-18"
    And I press the expense button "Save Expense"
    Then I should see "Expense created!"
    And I should be on the group page for "Roommates"
    