source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.3"

# Asset pipeline and frontend
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Database
gem "sqlite3", ">= 2.1"

# Web server
gem "puma", ">= 5.0"

# JSON APIs
gem "jbuilder"

# Authentication & OAuth
gem "devise"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection", "~> 1.0.0"

# Pagination and Excel import
gem "kaminari", "~> 1.2"
gem "roo", "~> 3.0"

# Windows timezone support
gem "tzinfo-data", platforms: %i[windows jruby]

# Cache / Queue / Cable backends
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Boot optimization
gem "bootsnap", require: false

# Deployment
gem "kamal", require: false

# HTTP acceleration for Puma
gem "thruster", require: false

# Optional Active Storage image processing
gem "image_processing", "~> 1.2"

gem "groupdate"
gem "ruby-openai"
gem "dotenv-rails"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 8.0"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver"
  gem "cucumber-rails", "~> 4.0", require: false
  gem "database_cleaner-active_record", "~> 2.2"
  gem "rails-controller-testing"
  gem "factory_bot_rails"
  gem "simplecov", require: false
  gem "simplecov-console", require: false
  gem "shoulda-matchers", "~> 5.0"
end
