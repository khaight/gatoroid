$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'

gem 'mocha', '>= 0.9.8'

require 'mocha'
require 'mongoid'
require 'gatoroid'
require 'bson'
require 'rspec'
require 'rspec/autorun'

Time.zone = "UTC"
Mongoid.configure do |config|
  config.connect_to("gatoroid_test")
end

puts "Mongoid::VERSION:#{Mongoid::VERSION}\nMoped::VERSION:#{Moped::VERSION}"

RSpec.configure do |config|
  config.mock_with :mocha

  # keep our mongo DB all shiney and new between tests
  require 'database_cleaner'
  
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end
  
  config.before(:each) do
    DatabaseCleaner.clean
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end
  
end