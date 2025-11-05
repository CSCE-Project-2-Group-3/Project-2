# Expense Tracker - Technical Documentation

## Table of Contents

1.  [System Overview](https://www.google.com/search?q=%23system-overview)
2.  [Prerequisites](https://www.google.com/search?q=%23prerequisites)
3.  [Local Development Setup](https://www.google.com/search?q=%23local-development-setup)
4.  [Architecture](https://www.google.com/search?q=%23architecture)
5.  [Database Schema](https://www.google.com/search?q=%23database-schema)
6.  [Testing](https://www.google.com/search?q=%23testing)
7.  [Deployment](https://www.google.com/search?q=%23deployment)
8.  [Development Workflow](https://www.google.com/search?q=%23development-workflow)
9.  [Troubleshooting](https://www.google.com/search?q=%23troubleshooting)

-----

## 1\. System Overview

**Expense Tracker** is a Ruby on Rails 8.0.4 application designed for collaborative financial management, built for the CSCE 606 Software Engineering course at Texas A\&M University. It allows users to track personal expenses, manage and split bills within groups, and gain insights into their spending habits through an AI-powered dashboard.

### Key Features

  * Individual & Group Expense Tracking
  * Social Bill Splitting with participant tracking
  * AI-Powered Dashboard Summaries (OpenAI)
  * Interactive AI-powered insights for all dashboard widgets
  * Direct user-to-user messaging (Conversations)
  * Group management with unique join codes
  * CSV Expense Import/Export
  * User authentication with Devise (Email/Password + Google OAuth2)

### Technology Stack

  * **Framework**: Ruby on Rails 8.0.4
  * **Ruby Version**: 3.3.0
  * **Database**: SQLite3 (Development), PostgreSQL (Production)
  * **Web Server**: Puma
  * **Background Jobs**: Default Rails `async` queue (no Redis/Sidekiq)
  * **Testing**: RSpec (Unit/Controller), Cucumber (Feature/Acceptance)
  * **Code Quality**: SimpleCov (100% Coverage), RuboCop
  * **Deployment**: GitHub Actions (CI), Heroku (Production)
  * **Authentication**: Devise, Omniauth-Google-OAuth2
  * **AI Integration**: OpenAI API
  * **Frontend**: Hotwire (Turbo) with Tailwind CSS (via CDN)
  * **File Storage**: Active Storage (local/disk in dev)

-----

## 2\. Prerequisites

Before setting up Expense Tracker locally, ensure you have the following installed:

### Required Software

  * **Ruby**: 3.3.0

    ```bash
    # Using rbenv
    rbenv install 3.3.0
    rbenv global 3.3.0
    ```

  * **PostgreSQL**: 12 or higher (for Production/Heroku)

    ```bash
    # macOS (using Homebrew)
    brew install postgresql@14
    brew services start postgresql@14

    # Ubuntu/Debian
    sudo apt-get install postgresql postgresql-contrib
    sudo service postgresql start
    ```

  * **SQLite3**: (for Development)

    ```bash
    # Ubuntu/Debian
    sudo apt-get install sqlite3 libsqlite3-dev
    ```

  * **Bundler**: Gem dependency manager

    ```bash
    gem install bundler
    ```

### Required API Keys

You'll need the following API keys to run the application, stored in `config/credentials.yml.enc`:

1.  **OpenAI API Key**: For AI-powered dashboard summaries

      * Sign up at [https://platform.openai.com/](https://platform.openai.com/)
      * Generate an API key from your dashboard

2.  **Google OAuth2 Keys**: For user sign-in

      * Visit [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
      * Create a new project (if not already)
      * Configure OAuth consent screen: Choose External, fill out required fields (app name, email, etc.), add `http://localhost:3000` under Authorized domains, save and publish (testing mode is fine for local use)
      * Go to Credentials → Create Credentials → OAuth Client ID
      * Choose Web application
      * Add redirect URI:
      ```
        http://localhost:3000/users/auth/google_oauth2/callback
      ```
      * Click Create
      * Copy the Client ID and Client Secret → place them under `google_oauth:` in your credentials file

      For details: https://console.cloud.google.com/apis/credentials

3. **Gmail App Password**: For forgot-my-password email sending

      * Go to https://myaccount.google.com/security
      * Enable 2-Step Verification (required)
      * Scroll down to App passwords
      * Select: App: Mail, Device: Other (Custom name) → e.g. RailsApp
      * Copy the 16-character password shown
      * Use this as your `gmail.password` above

-----

## 3\. Local Development Setup

### Step 1: Clone the Repository

```bash
# Clone from GitHub
git clone https://github.com/[Your-Repo-Path]/Project-2.git
cd Project-2
```

### Step 2: Install Dependencies

```bash
# Install Ruby gems
bundle install
```

### Step 3: Configure Environment Variables

This project uses the encrypted `config/credentials.yml.enc` file.

```bash
# Edit the encrypted credentials file
bin/rails credentials:edit
```

Add your keys to the file:

```yaml
openai:
  api_key: "sk-..."

google_oauth2:
  client_id: "..."
  client_secret: "..."
```

### Step 4: Setup SQLite3 Database

```bash
# Update config/database.yml to use SQLite3 in development
# (The default adapter: sqlite3, database: storage/development.sqlite3 is fine)

# Create the databases
rails db:create

# Run migrations
rails db:migrate

# (Optional) Seed the database with sample data
rails db:seed
```

### Step 5: Start the Development Server

This project uses `Procfile.dev` to manage processes.

```bash
# Start all services (web server)
bin/dev
```

This typically starts:

  * Web server (Puma) on http://localhost:3000

### Step 6: Access the Application

Open your browser and navigate to:

  * **Application**: http://localhost:3000

-----

## 4\. Architecture

### System Architecture

The application follows a standard monolithic Rails architecture. It does not use external job processors like Redis/Sidekiq, relying on the built-in `async` queue for background tasks.

```
+-------------------------------------------------------------+
|                Client Browser (PC/Mobile)                   |
| (Hotwire/Turbo UI driving interactions)                     |
+------------------------------^------------------------------+
                               |
                               | HTTP/HTTPS
                               |
+------------------------------v------------------------------+
|               Rails Application (Puma Server)               |
|                                                             |
| +-------------------------+     +-------------------------+ |
| |     Controllers         |     |      Services Layer       | |
| | (Pages, Expenses,       |     | (DashboardDataService)  | |
| |  Groups, Widgets,       |     | (DashboardAiAnalyzer)   | |
| |  Conversations,         |     | (Imports::ExpensesImport) | |
| |  Messages...)           |     +-------------------------+ |
| +-----------+-------------+                   |             |
|             | (Interacts with)                | (Uses)      |
|             |                                 |             |
| +-----------v-------------+                   |             |
| |       Models            |                   |             |
| | (User, Expense, Group,  |                   |             |
| |  Message, etc.)         |                   |             |
| +-----------+-------------+                   |             |
|             | (Reads/Writes)                  |             |
|             |                                 |             |
+-------------|---------------------------------|-------------+
              |                                 |
              | (DB queries)                    | (API calls)
              |                                 |
+-------------v-------------+     +-------------v-------------+
|    PostgreSQL (Prod) /    |     |    External Services      |
|     SQLite3 (Dev)         |     |                           |
|                           |     | +-----------------------+ |
| +-----------------------+ |     | |     OpenAI API        | |
| | Database Schema       | |     | | (For AI Summaries)    | |
| | (Users, Expenses,     | |     | +-----------------------+ |
| |  Groups, Messages...) | |     | +-----------------------+ |
| +-----------------------+ |     | | Google OAuth 2.0      | |
|                           |     | | (For Authentication)  | |
|                           |     | +-----------------------+ |
+---------------------------+     +---------------------------+
```

### Application Structure

```
Project-2/
├── app/
│   ├── controllers/
│   │   ├── pages_controller.rb         # Handles Dashboard
│   │   ├── expenses_controller.rb      # Expense CRUD, CSV Import
│   │   ├── groups_controller.rb        # Group CRUD, Join
│   │   ├── conversations_controller.rb # Messaging list
│   │   ├── messages_controller.rb      # Sending messages
│   │   └── widget_summaries_controller.rb # AI Insight Modals
│   ├── models/
│   │   ├── user.rb
│   │   ├── expense.rb
│   │   ├── group.rb
│   │   ├── category.rb
│   │   ├── conversation.rb
│   │   ├── message.rb
│   │   └── group_membership.rb
│   ├── services/
│   │   ├── dashboard_data_service.rb     # Logic for dashboard data
│   │   ├── dashboard_ai_analyzer_service.rb # AI prompt generation
│   │   └── imports/expenses_import.rb  # CSV parsing logic
│   ├── views/
│   │   ├── pages/dashboard.html.erb    # Main dashboard view
│   │   ├── groups/show.html.erb        # Group detail page
│   │   └── conversations/show.html.erb # Chat interface
│   └── jobs/                         # (Currently unused)
├── config/
│   ├── routes.rb                     # URL routing
│   └── database.yml
├── db/
│   ├── migrate/
│   └── schema.rb
├── spec/
│   ├── controllers/                  # RSpec controller tests
│   ├── features/                     # RSpec/Capybara feature tests
│   ├── models/                       # RSpec model tests
│   └── services/                     # RSpec service tests
└── features/                         # Cucumber .feature files
    └── step_definitions/
```

### Frontend Architecture

This project uses a **"no-custom-JS"** frontend approach.

  * **Tailwind CSS CDN**: Loaded in `app/views/layouts/application.html.erb`. This provides a modern utility-class CSS framework without requiring a Node.js build pipeline.
  * **Hotwire (Turbo)**: Used for SPA-like navigation.
      * `Turbo Frames` are used extensively for modal popups (like the AI widget insights and new category form).
      * `Turbo Streams` are used for real-time page updates (like posting a new message).
  * **No Custom JavaScript**: The application does not use custom Stimulus controllers or `app/javascript` files, relying entirely on the declarative features of Turbo Frames and Streams.

-----

## 5\. Database Schema

The schema is defined by `db/schema.rb` and consists of 9 tables.

### Entity Relationship Diagram (ERD)

This ERD is based on your `schema.rb` file.

```
+---------------+      +---------------------+      +------------+
|     Users     |      |  GroupMemberships   |      |   Groups   |
|---------------|      |---------------------|      |------------|
| id (PK)       |<--+--| user_id (FK)      |>--+--| id (PK)    |
| email         |  |   | group_id (FK)     |   |  | name       |
| full_name     |  |   +---------------------+   |  | join_code  |
| ... (devise)  |  |                               +-----+------+
| ... (omniauth)|  |                                     |
+-------+-------+  |                                     |
        |          |                                     |
+-------+-------+  |   +-----------------+               |
| Conversations |  |   |    Categories   |               |
|---------------|  |   |-----------------|               |
| id (PK)       |  |   | id (PK)         |               |
| user_a_id (FK)|>-+   | name            |               |
| user_b_id (FK)|>-+   +--------+--------+               |
+-------+-------+              |                        |
        |                      | 1..N                   | 1..N (Optional)
        | 1..N                 |                        |
        |                      |                        |
+-------v-------+      +-------v-------+                |
|   Messages    |      |    Expenses   |                |
|---------------|      |---------------|                |
| id (PK)       |      | id (PK)       |<---------------+
| body          |      | title         |
| conversation_id>--+  | amount        |
| user_id (FK)  |>-+  | category_id (FK)>--+
+-------+-------+      | user_id (FK)  |>-+
        |              | group_id (FK) |o-+
        | 1..N         | ...           |
        |              +--------+--------+
+-------v-------+               | 1..N
|   Comments    |               |
|---------------|               |
| id (PK)       |               |
| body          |               |
| user_id (FK)  |>-+             |
| expense_id (FK)>--------------+
+---------------+

+--------------------+
|  MessageExpenses   |  (Expense Quoting)
|--------------------|
| id (PK)            |
| message_id (FK) >--+ (Refers to Messages)
| expense_id (FK) >--+ (Refers to Expenses)
+--------------------+
```

### Table Descriptions

#### `users`

Stores user accounts and authentication (Devise + Omniauth).
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `email` | `string` | NOT NULL, UNIQUE, DEFAULT "" |
| `encrypted_password` | `string` | NOT NULL, DEFAULT "" |
| `full_name` | `string` | |
| `uid` | `string` | |
| `avatar_url` | `string` | |
| `provider` | `string` | |
| `reset_password...` | `...` | |
| `remember_created_at` | `datetime` | |

#### `groups`

Stores user-created groups for sharing expenses.
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `name` | `string` | |
| `join_code` | `string` | UNIQUE |

#### `group_memberships`

Join table linking Users and Groups (Many-to-Many).
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `user_id` | `integer` | NOT NULL, FOREIGN KEY (users) |
| `group_id` | `integer` | NOT NULL, FOREIGN KEY (groups) |

#### `categories`

Stores expense categories.
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `name` | `string` | |

#### `expenses`

The core table, tracks individual and group spending.
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `category_id` | `integer` | NOT NULL, FOREIGN KEY (categories) |
| `title` | `string` | |
| `notes` | `text` | |
| `amount` | `decimal(12,2)` | |
| `spent_on` | `date` | |
| `user_id` | `integer` | NOT NULL, FOREIGN KEY (users) |
| `group_id` | `integer` | FOREIGN KEY (groups), NULL |
| `participant_ids` | `text` | NOT NULL, DEFAULT "[]" |

#### `comments`

Stores comments on expenses.
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `expense_id` | `integer` | NOT NULL, FOREIGN KEY (expenses) |
| `user_id` | `integer` | NOT NULL, FOREIGN KEY (users) |
| `body` | `text` | NOT NULL |

#### `conversations`

Links two users for direct messaging.
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `user_a_id` | `integer` | |
| `user_b_id` | `integer` | |

#### `messages`

Stores individual chat messages.
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `conversation_id` | `integer` | NOT NULL, FOREIGN KEY (conversations) |
| `user_id` | `integer` | NOT NULL, FOREIGN KEY (users) |
| `body` | `text` | |
| `quoted_expense_id` | `integer` | (Deprecated by `message_expenses`) |

#### `message_expenses`

Join table linking a Message to a quoted Expense (Many-to-Many).
| Column | Type | Constraints |
|---|---|---|
| `id` | `bigint` | PRIMARY KEY |
| `message_id` | `integer` | NOT NULL, FOREIGN KEY (messages) |
| `expense_id` | `integer` | NOT NULL, FOREIGN KEY (expenses) |

-----

## 6\. Testing

Expense Tracker aims for 100% test coverage using RSpec for unit/controller tests and Cucumber for acceptance tests.

### Testing Stack

  * **RSpec**: Unit, controller, and service tests.
  * **Cucumber**: Acceptance/feature tests (BDD).
  * **Capybara**: Feature testing with browser simulation.
  * **FactoryBot**: Generating test data.
  * **SimpleCov**: Code coverage reporting (100% target achieved).

### Running Tests

#### RSpec (Unit/Controller/Service Tests)

```bash
# Run all RSpec tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/controllers/pages_controller_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

#### Cucumber (Acceptance Tests)

```bash
# Run all Cucumber features
bundle exec cucumber
```

#### Code Coverage

```bash
# Generate SimpleCov coverage report
# Note: RSpec must be run for coverage to be generated
bundle exec rspec

# View coverage report
open coverage/index.html  # macOS
xdg-open coverage/index.html # Linux
```

### Writing Tests

#### RSpec Example (Service)

```ruby
# spec/services/dashboard_data_service_spec.rb
require 'rails_helper'
require 'ostruct'

RSpec.describe DashboardDataService, type: :service do
  let!(:user) { create(:user) }
  # ... (setup) ...

  context "with no filters" do
    it "fetches all data" do
      data = described_class.new(user).fetch_data
      expect(data.personal_total).to eq(50)
      expect(data.group_total).to eq(1000)
    end
  end
end
```

#### Cucumber Example

```gherkin
# features/dashboard_summary.feature
Feature: Dashboard Page
  As a logged-in user
  I want to see my dashboard
  So I can understand my spending habits.

  Background:
    Given I am a registered user and I am logged in
    And I have a "Food" expense "Groceries" with amount $150
    And I have a "Housing" group expense "Rent" with amount $800

  Scenario: Filtering the dashboard
    When I go to the dashboard page
    Then I should see "Total Spent: $150.00"
    And I should see "Total Spent (in groups): $800.00"
    When I select "Food" from the "Category" dropdown
    And I click the "Filter" button
    Then I should see "Total Spent: $150.00"
    And I should see "Total Spent (in groups): $800.00"
```

-----

## 7\. Deployment

### CI/CD (GitHub Actions)

The project is configured to run all RSpec and Cucumber tests on every push to `main` or any pull request.

**Problem:** The `Gemfile.lock` is often generated on a Windows machine (`x64-mingw-ucrt`), causing the Linux-based GitHub Actions runner to fail (`exit code 16`).

**Solution:** Before committing, always update your lockfile to include the Linux platform:

```bash
bundle lock --add-platform x86_64-linux
git add Gemfile.lock
git commit -m "Add linux platform to lockfile for CI"
```

### Production Deployment (Heroku)

The app is configured for Heroku deployment and uses PostgreSQL in production.

1.  **Add Heroku Remote**
    ```bash
    heroku git:remote -a [your-heroku-app-name]
    ```
2.  **Add PostgreSQL Addon**
    ```bash
    heroku addons:create heroku-postgresql:mini
    ```
3.  **Push to Deploy**
    ```bash
    git push heroku main
    ```
4.  **Run Migrations**
    ```bash
    heroku run rails db:migrate
    ```
5.  **Monitor**
    ```bash
    heroku logs --tail
    ```

-----

## 8\. Development Workflow

### Git Branching Strategy

This project uses **GitHub Flow**:

1.  All work is done in feature branches (e.g., `ai-and-ui-optimization`).
2.  Branches are created from `main`.
3.  When a feature is complete, a Pull Request (PR) is opened to merge back into `main`.

### Pull Request (PR) Checklist

  * [ ] All RSpec tests pass (`bundle exec rspec`).
  * [ ] All Cucumber tests pass (`bundle exec cucumber`).
  * [ ] Code coverage is 100%.
  * [ ] PR has been reviewed and approved by at least one other team member.

-----

## 9\. Troubleshooting

### Common Issues

#### `ActiveRecord::PendingMigrationError`

**Problem**: The database is not up-to-date with migration files.
**Solution**:

```bash
bin/rails db:migrate
```

#### `Capybara::ElementNotFound` (in Cucumber)

**Problem**: A test step (e.g., `When I click "Save"`) cannot find the button.
**Solution**: This almost always means the text in your `.feature` file is out of sync with your UI.

  * **Find the real text:** Run the app and look at the button. If it says "Create Group", not "Save"...
  * **Fix the test:** Change the step in your `.feature` file to `When I click "Create Group"`.

#### `NoMethodError: undefined method '...' for nil` (in RSpec)

**Problem**: A request spec (in `spec/requests/`) or controller spec fails, often on a line involving `current_user`.
**Solution**: Request/controller specs do not log in a user by default. You **must** add `sign_in user` (using `Devise::Test::ControllerHelpers` or `Devise::Test::IntegrationHelpers`) to your test's `before` block.

#### `Bundle install` fails on CI (Exit Code 16)

**Problem**: `Your bundle only supports platforms ["x64-mingw-ucrt"]...`
**Solution**: Your `Gemfile.lock` needs to support the Linux platform.

```bash
bundle lock --add-platform x86_64-linux
git add Gemfile.lock
git commit -m "Add linux platform for CI"
```
