## Expense Tracker - Domain-Driven Design (DDD) Document

### 1\. Introduction

This document outlines the Domain-Driven Design (DDD) for the **Expense Tracker** application. Its purpose is to define the project's **Ubiquitous Language**, identify its **Bounded Contexts**, and detail the core **Aggregates**, **Entities**, and **Value Objects** that model the business logic. This serves as a guide for development to ensure the code (models, services, controllers) is a direct reflection of the domain.

-----

### 2\. Ubiquitous Language

This is the shared vocabulary used by developers, testers, and (hypothetically) business stakeholders. All code and tests should use these terms.

  * **User**: The account holder, authenticated via Devise (Email or Google).
  * **Group**: A collection of `Users` created to share and split expenses.
  * **Member**: A `User` who belongs to a `Group` via a `GroupMembership`.
  * **Join Code**: The unique, 8-character string (`groups.join_code`) a `User` must provide to join a `Group`.
  * **Expense**: A single financial transaction record. This is a central concept.
  * **Personal Expense**: An `Expense` with a `nil` `group_id`. It belongs only to the `User`.
  * **Group Expense**: An `Expense` with a `group_id`. It is associated with a `Group` and visible to its `Members`.
  * **Creator / Owner**: The `User` who created the `Expense` (defined by `expense.user_id`).
  * **Participant**: A `User` included in an `Expense` split (stored in the `expense.participant_ids` array).
  * **Split**: The act of dividing an `Expense` cost among `Participants`.
  * **Dashboard**: The main summary view for a logged-in `User` (`PagesController#dashboard`).
  * **Widget**: A component on the `Dashboard` (e.g., "Personal Expenses" list, "Category Pie Chart").
  * **Insight**: An AI-generated text summary for a `Widget`, provided by the `DashboardAiAnalyzerService`.
  * **Conversation**: A private, one-on-one chat thread between two `Users`.
  * **Message**: A single chat entry within a `Conversation`.
  * **Quoted Expense**: An `Expense` attached to a `Message` (via `MessageExpenses`) to provide context.

-----

### 3\. Bounded Contexts

While the application is a monolith, its logic is divided into distinct Bounded Contexts.

  * **1. Identity & Access (IAM) Context**

      * **Description:** Manages "who" a user is and how they prove it.
      * **Core Entities:** `User`
      * **Logic:** User registration, login/logout, password recovery (Devise), and Google OAuth (`OmniauthCallbacksController`).

  * **2. Group Management Context**

      * **Description:** Manages the social aspect of creating and joining groups. This is a **Core Domain**.
      * **Core Aggregates/Entities:** `Group` (Aggregate Root), `GroupMembership`.
      * **Logic:** Creating groups, generating `Join Codes`, joining groups.
      * **Controllers:** `GroupsController`.

  * **3. Expense Management Context**

      * **Description:** Manages the creation and details of financial transactions. This is a **Core Domain**.
      * **Core Aggregates/Entities:** `Expense` (Aggregate Root), `Category`, `Comment`.
      * **Logic:** Expense CRUD, bill splitting (`participant_ids`), CSV import (`Imports::ExpensesImport`).
      * **Controllers:** `ExpensesController`.

  * **4. Analytics & Insights Context**

      * **Description:** A supporting context that reads data from other contexts to provide analysis.
      * **Core Services:** `DashboardDataService`, `DashboardAiAnalyzerService`.
      * **Logic:** Aggregating personal vs. group totals, filtering by date/category, generating AI summaries.
      * **Controllers:** `PagesController` (Dashboard), `WidgetSummariesController` (AI Modals).

  * **5. Messaging Context**

      * **Description:** A supporting context that handles user-to-user communication.
      * **Core Aggregates/Entities:** `Conversation` (Aggregate Root), `Message`, `MessageExpense`.
      * **Logic:** Starting new conversations, sending messages, quoting expenses in a message.
      * **Controllers:** `ConversationsController`, `MessagesController`.

-----

### 4\. Context Map

This map shows how the Bounded Contexts interact within the monolith.

```
+--------------------------+
|  Identity & Access (IAM) |  (Upstream: All contexts depend on User)
+------------+-------------+
             |
             v
+--------------------------+   (Shared Kernel: Expense)   +-----------------------+
|   Group Management       | <-------------------------- |   Expense Management  |
|   (Core Domain)          |           (Expense.group_id)  |   (Core Domain)       |
+------------+-------------+ -------------------------- +-----------+-----------+
             |                                                       |
             | (Reads Groups, Users)                                 | (Reads Expenses)
             |                                                       |
+------------v-------------+                               +---------v-----------+
|   Messaging              |                               | Analytics & Insights|
|   (Supporting Domain)    |---- (Quotes Expense) -------->| (Supporting Domain) |
+--------------------------+                               +---------------------+
```

  * **Shared Kernel:** The `Expense` and `User` models are the primary "Shared Kernel." `Group Management` and `Expense Management` are tightly coupled.
  * **Upstream/Downstream:** `Analytics & Insights` is fully downstream (a "consumer") of `Expense Management` and `Group Management`. It reads their data but does not modify it.

-----

### 5\. Core Domain Model

This section details the primary Aggregates (objects that are treated as a single unit).

#### User (Aggregate)

  * **Aggregate Root:** `User`
  * **Entities:** `GroupMembership`, `Expense`, `Comment`, `Conversation` (via `user_a`/`user_b`), `Message`.
  * **Description:** The `User` is the central aggregate that "owns" most other data in the application. All business logic is gated by the `current_user`.
  * **Invariants (Rules):**
      * A `User`'s `email` must be unique.
      * A `User` can be linked to an OmniAuth `provider` and `uid`.

#### Group (Aggregate)

  * **Aggregate Root:** `Group`
  * **Entities:** `GroupMembership`
  * **Related (via `Expense`):** `Expense`
  * **Value Objects:** `JoinCode` (a unique, random string)
  * **Description:** Represents a collection of users. Its primary business logic is managing membership via the `JoinCode`.
  * **Invariants (Rules):**
      * A `Group` must have a `name`.
      * A `JoinCode` must be unique.
      * A `User` can only be a `Member` of a `Group` once.

#### Expense (Aggregate)

  * **Aggregate Root:** `Expense`
  * **Entities:** `Comment`
  * **Value Objects:** `Amount` (a `Decimal`), `ParticipantList` (a `text` field storing a JSON array of User IDs)
  * **Description:** The core financial object. It can be a `Personal Expense` (no `group_id`) or a `Group Expense`.
  * **Invariants (Rules):**
      * An `Expense` *must* have a `Creator` (`user_id`).
      * An `Expense` *must* have a `Category` (`category_id`). This is a key business rule enforced by validation.
      * An `Expense` `amount` must be a valid decimal.
      * `participant_ids` must be an array of `User` IDs.

#### Conversation (Aggregate)

  * **Aggregate Root:** `Conversation`
  * **Entities:** `Message`
  * **Related (via `MessageExpense`):** `Expense`
  * **Description:** A thread of communication between two users.
  * **Invariants (Rules):**
      * A `Conversation` must be between two distinct `Users` (`user_a_id` \!= `user_b_id`).
      * Only `user_a` or `user_b` can view or post `Messages` to the `Conversation`.

-----

### 6\. Domain Events

These are key "things that happen" in the system that other parts might react to.

  * `UserSignedUp` (Devise)
  * `UserLoggedInWithGoogle` (OmniAuth)
  * `GroupCreated` (`GroupsController#create`)
  * `UserJoinedGroup` (`GroupsController#join`)
  * `ExpenseCreated` (`ExpensesController#create`)
  * `ExpenseSplit` (An `ExpenseCreated` event where `participant_ids.count` \> 1)
  * `ExpenseImported` (`Imports::ExpensesImport` service)
  * `CommentPosted` (`CommentsController#create`)
  * `ConversationStarted` (`ConversationsController#create`)
  * `MessageSent` (`MessagesController#create`)
  * `ExpenseQuotedInMessage` (A `MessageSent` event with `quoted_expense_ids`)
  * `DashboardViewed` (`PagesController#dashboard`)

-----

### 7\. Application & Domain Services

Services are objects that hold business logic that doesn't naturally fit on a single model.

  * **`DashboardDataService` (Application Service)**

      * **Responsibility:** Gathers and filters data from multiple aggregates (`Expense`, `Group`, `Category`) for the `PagesController`. It coordinates data retrieval but does not contain core business logic. It is responsible for applying the dashboard filters.

  * **`DashboardAiAnalyzerService` (Application Service)**

      * **Responsibility:** An orchestrator service. It takes the data from `DashboardDataService`, formats it into a human-readable prompt, and sends it to the external OpenAI API to request an "Insight." It does not contain domain logic itself.

  * **`Imports::ExpensesImport` (Domain Service)**

      * **Responsibility:** Contains complex business logic for parsing a CSV file, finding or creating `Categories`, and creating `Expense` records for a `User`. This is a true Domain Service as it performs a complex operation that spans multiple models.
