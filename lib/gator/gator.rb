# encoding: utf-8
require 'mongoid'
module Mongoid #:nodoc:
  module Gator #:nodoc:
    def self.included(base)
      base.class_eval do
        include  Mongoid::Document 
        include Mongoid::Attributes::Dynamic
        extend ClassMethods
        class_attribute :gator_keys, :gator_fields
        self.gator_keys = []
        self.gator_fields = []
        delegate :gator_keys, :to => "self.class"
      end
    end
      
    module ClassMethods
      def field(name=nil)
        gator_keys << name
      end
        
      def gator_field(name=nil)
        gator_fields << name
        create_accessors(name)
      end
        
      protected
      def create_accessors(name)
        define_method(name) do
          Gatorer.new(self, name)
        end
        
        define_singleton_method(name) do
            Gatorer.new(self, name)
        end
      end  
    end
    
  end
end