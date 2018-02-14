$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'gator/version'
Gem::Specification.new do |gem|
  gem.name    = 'gatoroid'
  gem.version = Mongoid::Gator::VERSION

  gem.authors     = ['Kevin Haight']
  gem.email       = ['kevinjhaight@gmail.com']
  gem.homepage    = 'https://github.com/khaight/gatoroid'
  gem.summary     = 'Gatoroid is a way to store analytics using the poweful features of MongoDB for scalability'
  gem.description = ''
  gem.license     = 'MIT'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }

  gem.add_dependency 'mongoid', '~> 5.1.0'

  gem.add_development_dependency 'rubocop', '0.36.0'
  gem.add_development_dependency 'database_cleaner', '1.6.1'
  gem.add_development_dependency 'rspec', '~> 3.1', '>= 3.6'
  gem.add_development_dependency 'mocha', '1.1.0'
end
