$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'

require 'mocha'
require 'mongoid'
require 'gatoroid'
require 'bson'
require 'rspec'
require 'database_cleaner'

Time.zone = 'UTC'
Mongoid.load!('spec/mongoid.yml', :test)

puts "Mongoid::VERSION:#{Mongoid::VERSION}"

RSpec.configure do |config|
  config.mock_with :mocha

  # keep our mongo DB all shiney and new between tests

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
