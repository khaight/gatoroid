# encoding: utf-8
require 'rubygems'

gem "mongoid", ">= 1.9.0"

#require 'gator/errors'
#require 'gator/core_ext'
#require 'gator/reader_extender'
#require 'gator/readers'
#require 'gator/gator'
#require 'gator/aggregates'
#require 'gator/gator_aggregates'
#require '../lib/gator/gatoring.rb'
#require File.expand_path('../gator/errors.rb', __FILE__)
#require File.expand_path('../gator/reader_extender.rb', __FILE__)
require File.expand_path('../gator/errors.rb', __FILE__)
require File.expand_path('../gator/javascript.rb', __FILE__)
require File.expand_path('../gator/readers.rb', __FILE__)
require File.expand_path('../gator/gatorer.rb', __FILE__)
require File.expand_path('../gator/gator.rb', __FILE__)
#require File.expand_path('../../lib/gator.rb', __FILE__)

module Mongoid
  module Gator
    VERSION = File.read(File.expand_path("../VERSION", File.dirname(__FILE__)))
  end
end