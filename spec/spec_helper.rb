
require 'coveralls'
Coveralls.wear!

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../spec/dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'rspec/collection_matchers'

require "factory_girl_rails"
require "database_cleaner"
require 'capybara'
require 'capybara/rspec'
require 'shoulda/matchers/integrations/rspec'
require 'timecop'

require "espinita"
require 'support/schema'
require 'support/models'

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :truncation
  end
end
