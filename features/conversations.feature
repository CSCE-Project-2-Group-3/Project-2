Feature: Direct messaging between users
  As a signed-in user
  I want to message another user about an expense
  So that we can discuss privately

  Background:
    Given the following users exist:
      | full_name | email              | password    |
      | Alice Doe | alice@example.com  | password123 |
      | Bob Roe   | bob@example.com    | password123 |

    And I am logged in as "alice@example.com"

  Scenario: Start a new conversation from an expense
    Given an expense posted by "bob@example.com"
    When I visit that expense page
    And I click the message button "Send Message"
    Then I should be on the conversation page with "Bob Roe"
    And I should see in conversation "No messages yet"

  Scenario: Send and view messages
    Given a conversation between "alice@example.com" and "bob@example.com"
    When I send a message saying "Hi Bob!"
    Then I should see "Hi Bob!"
    And Bob should see the same message when he logs in
