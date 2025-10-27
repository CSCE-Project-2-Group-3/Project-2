Feature: User Authentication
  As a user
  I want to be able to authenticate
  So that I can access the application

  Scenario: View home page when not logged in
    Given I am not logged in
    When I am on the home page
    Then I should see "Welcome to Expense Tracker"
    And I should see "Login"
    And I should see "Create Account"
    And I should not see "Welcome,"


  Scenario: Sign up with email and password
    Given I am not logged in
    When I am on the home page
    And I click on "Create Account"
    Then I should be on the registration page
    When I fill in "Email" with "newuser@example.com"
    And I fill in password fields with "securepassword123"
    And I click the "Sign up" button
    Then I should see "Welcome! You have signed up successfully."

  Scenario: Sign in with email and password
    Given I am not logged in
    And a user exists with email "user@example.com" and password "password123"
    When I am on the home page
    And I click on "Login" with class "btn-primary"
    Then I should be on the login page
    When I fill in "Email" with "user@example.com"
    And I fill in "Password" with "password123"
    And I click the "Log in" button
    Then I should see "Welcome, user@example.com!"

  Scenario: Sign out
    Given I am logged in
    When I am on the home page
    And I click the "Logout" button
    Then I should see "Log in"
    And I should see "Sign up"
    And I should not see "Welcome"



  Scenario: View login form elements
    Given I am not logged in
    When I visit the login page
    Then I should see "Log in"
    And I should see "Email"
    And I should see "Password"
    And I should see "Remember me"

  Scenario: View registration form elements
    Given I am not logged in
    When I visit the registration page
    Then I should see "Sign up"
    And I should see "Email"
    And I should see "Password"
    And I should see "Password confirmation"