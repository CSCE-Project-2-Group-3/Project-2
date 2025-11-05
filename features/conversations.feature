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

