Feature: Group and Social Features
  As a user
  I want to manage groups and shared expenses
  So that I can track, split, and discuss group spending

  # ------------------------------
  # Create a Group for Shared Expenses
  # ------------------------------

  Scenario: Successfully create a new group
    Given I am logged in
    And I am on the "Groups" page
    When I click "Create Group"
    And I enter "Roommates 2025" as the group name
    And I click "Save"
    Then I should see "Group created successfully"
    And I should see "Roommates 2025" in my group list

  Scenario: Fail to create group without a name
    Given I am logged in
    And I am on the "Groups" page
    When I click "Create Group"
    And I leave the group name blank
    And I click "Save"
    Then I should see "Group name can't be blank"

  # ------------------------------
  # Invite Users to a Group
  # ------------------------------

  Scenario: Successfully invite a user to a group
    Given I am a member of "Roommates 2025"
    When I click "Invite Member"
    And I enter "alex@example.com"
    And I click "Send Invitation"
    Then I should see "Invitation sent successfully"

  Scenario: Fail to invite a non-existent user
    Given I am a member of "Roommates 2025"
    When I click "Invite Member"
    And I enter "nonexistent@example.com"
    And I click "Send Invitation"
    Then I should see "User not found"

  # ------------------------------
  # Split Expense Among Group Members
  # ------------------------------

  Scenario: Evenly split an expense among group members
    Given I am in the group "Roommates 2025" with 3 members
    When I add an expense titled "Groceries" for "$90"
    And I select "Split evenly"
    And I click "Save"
    Then I should see "Expense added successfully"
    And each member’s share should be "$30"

  Scenario: Fail to add expense without amount
    Given I am in the group "Roommates 2025"
    When I add an expense titled "Dinner" without an amount
    And I click "Save"
    Then I should see "Amount can't be blank"

  # ------------------------------
  # View Total Group Expense
  # ------------------------------

  Scenario: View total group expenses
    Given the group "Roommates 2025" has expenses of "$90" and "$60"
    When I visit the group summary page
    Then I should see "Total: $150"

  Scenario: View total when there are no expenses
    Given the group "New Group" has no expenses
    When I visit the group summary page
    Then I should see "Total: $0"

  # ------------------------------
  # Comment on a Group Expense
  # ------------------------------

  Scenario: Add a comment to a group expense
    Given I am viewing the "Groceries" expense in "Roommates 2025"
    When I type "Can we split snacks separately next time?" in the comment box
    And I click "Post Comment"
    Then I should see "Comment posted successfully"
    And I should see my comment in the thread

  Scenario: Fail to post an empty comment
    Given I am viewing the "Groceries" expense in "Roommates 2025"
    When I leave the comment box blank
    And I click "Post Comment"
    Then I should see "Comment can't be blank"

  # ------------------------------
  # View All Comments in a Group Expense Thread
  # ------------------------------

  Scenario: View all comments in a group expense thread
    Given the "Groceries" expense has 3 comments
    When I open the "Comments" section
    Then I should see all 3 comments in chronological order
