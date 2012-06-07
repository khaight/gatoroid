# encoding: utf-8
require 'rubygems'

gem "mongoid", ">= 1.9.0"

require File.expand_path('../gator/errors.rb', __FILE__)
require File.expand_path('../gator/javascript.rb', __FILE__)
require File.expand_path('../gator/readers.rb', __FILE__)
require File.expand_path('../gator/gatorer.rb', __FILE__)
require File.expand_path('../gator/gator.rb', __FILE__)

module Mongoid
  module Gator
    VERSION = File.read(File.expand_path("../VERSION", File.dirname(__FILE__)))
  end
end