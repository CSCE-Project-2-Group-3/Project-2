require 'capybara/rspec'

Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, respect_data_method: true)
end

Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 5
