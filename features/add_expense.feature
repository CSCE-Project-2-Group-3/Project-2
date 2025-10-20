Feature: Add an expense
  In order to track my spending
  As a user
  I want to add a new expense with a category

  Scenario: Successfully adding an expense
    Given I have a category called "Food"
    When I go to the new expense page
    And I fill in "Title" with "Lunch"
    And I fill in "Amount" with "10.50"
    And I fill in "Spent on" with "2025-10-18"
    And I select "Food" from "Category"
    And I press "Save Expense"
    Then I should see "Expense added successfully."
