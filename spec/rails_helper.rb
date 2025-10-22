# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Prevent database truncation if running in production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'devise'
require 'shoulda/matchers'
require 'capybara/rails'
require 'database_cleaner/active_record'

# Load any files in spec/support
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Apply pending migrations before tests
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # ✅ Rails 8 compatibility – no transactional fixture settings
  config.include ActiveRecord::TestFixtures if defined?(ActiveRecord::TestFixtures)
  config.fixture_paths = [Rails.root.join('spec/fixtures')] if config.respond_to?(:fixture_paths=)

  # Devise + Capybara helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Capybara::DSL, type: :feature

  # DatabaseCleaner setup to isolate test data
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Infer spec type & filter Rails noise
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

# Shoulda-Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
