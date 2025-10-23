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
  # Invite Users to a Group (Copyable Invite Link)
  # ------------------------------

  Scenario: Join group manually with invite code
    Given I am logged in
    And I am on the "Groups" page
    When I paste a valid invite code into the "Join Group" field
    And I click "Join"
    Then I should see "Joined Roommates 2025 successfully"

  Scenario: Fail to join with invalid invite code
    Given I am logged in
    And I am on the "Groups" page
    When I paste an invalid or expired invite code into the "Join Group" field
    And I click "Join"
    Then I should see "Invalid join code"

  Scenario: Fail to join if already a member
    Given I am logged in
    And I am already a member of "Roommates 2025"
    And I am on the "Groups" page
    When I paste a valid invite code into the "Join Group" field
    And I click "Join"
    Then I should see "You are already in this group."

  # ------------------------------
  # Split Expense Among Group Members
  # ------------------------------

  Scenario: Evenly split a $120 expense across four roommates
    Given I am logged in
    And I am in the group "Roommates 2025" with 4 members
    When I add an expense titled "Cleaning Service" for "$120"
    And I choose to split the bill with all group members
    And I click "Save"
    Then I should see "Expense created!"
    And each member’s share should be "$30"

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
