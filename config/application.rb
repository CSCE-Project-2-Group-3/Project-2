require_relative "boot"

# Load core Rails frameworks selectively (for better performance)
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ExpenseTracker
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 8.0
    config.load_defaults 8.0

    # Autoload lib directory but ignore non-Ruby files
    config.autoload_lib(ignore: %w[assets tasks])

    # Include custom service objects for eager loading
    config.eager_load_paths << Rails.root.join("app/services")

    # Configuration for the application, engines, and railties
    # These can be overridden in specific environment configs.
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Disable generation of system test files
    config.generators.system_tests = nil
  end
end
