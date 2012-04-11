# encoding: utf-8
module Mongoid  #:nodoc:
    module Gator
      class Gatorer

        include Readers
        
        # Initialize object
        def initialize(object, field)
           @object, @for = object, field
           create_accessors()
        end

        private
        
        # Get total for
        def total_for(date,grain,opts={})
         unless date.nil?
           begin
             return  @object.class.where(create_query_hash(date,grain,opts)).sum(@for)
           rescue
             return  @object.where(create_query_hash(date,grain,opts)).sum(@for)
          end
         end
        end
        
        # Get collections for
        def collection_for(date,grain, opts={})
          unless date.nil?
            return  @object.collection.group(:keyf => create_fkey(grain), 
                    :reduce => "function(obj,prev){for (var key in obj.#{@for}) {prev.#{@for} += obj.#{@for}}}",
                    :cond=>create_query_hash(date,grain,opts),
                    :initial => {@for => 0})
          end
        end
        
        # Convert date levels
        def convert_date_by_level(date,level)
          if date.is_a?(Range)
            sdate = date.first
            edate = date.last
          else
            sdate = date
            edate = date
          end
          case level
          when HOUR
            return sdate.change(:sec=>0), edate.change(:sec=>0) + 1.hour
          when DAY
            return sdate.change(:hour=>0).change(:sec=>0), edate.change(:hour=>0).change(:sec=>0) + 1.day
          when MONTH
            return sdate.change(:day=>1).change(:hour=>0).change(:sec=>0), edate.change(:day=>1).change(:hour=>0).change(:sec=>0) + 1.month
          end
        end
        
        # Create fkey
        def create_fkey(grain)
          case grain
          when HOUR
            fkey = Javascript.aggregate_hour
          when MONTH
            fkey = Javascript.aggregate_month
          else # DEFAULT TO DAY
            fkey = Javascript.aggregate_day
          end
          return fkey
        end
        
        protected   
        def create_accessors
          self.class.class_eval do 
            define_method :inc  do |  *args |       
              keys, date = gen_params(Hash[*args])
              inc_counter(keys,date)
            end
            
            define_method :dec  do | *args |       
                keys, date = gen_params(Hash[*args])
                dec_counter(keys,date)
            end
            
            define_method :add  do | how_many, *args |       
                keys, date = gen_params(Hash[*args])
                add_to_counter(how_many,keys,date)
            end
            
            define_method :reset  do |  *args |       
                keys, date = gen_params(Hash[*args])
                reset_counter(keys,date)
            end
          end
        end
        
        # Add
        def add_to_counter(how_much = 1, keys=[], date = Time.now)
          return if how_much == 0
          # Upsert value
          @object.collection.update(create_key_hash(keys,date.utc),
            {"$inc" => {
              "#{@for}" => how_much,
            }},
              :upsert => true
            )
        end
        
        # Reset Counter
        def reset_counter(keys=[], date = Time.now)
          # Upsert value
          @object.collection.update(create_key_hash(keys,date.utc),
            {"$set" => {
              "#{@for}" => 0,
            }},
              :upsert => true
            )
        end
        
        # Increment Counter
        def inc_counter(keys,date = Time.now)
          add_to_counter(1,keys,date)
        end
        
        # Decrement Counter
        def dec_counter(keys, date = Time.now)
           add_to_counter(-1,keys,date)
        end
        
        # Generate parameters
        def gen_params(params)
          date = Time.now # Set default date to now
          key_hash = Hash.new { |hash, key| hash[key] = [] }
          @object.gator_keys.each do| gk |
            raise Errors::ModelNotSaved, "Missing key value #{gk}" if params[gk].nil?
            key_hash[gk] = params[gk]
          end
          # Set Date 
          if !params[:date].nil?
            date = params[:date]
          end
          return key_hash, date
        end
        
        # Create Hash Key
        def create_key_hash(keys,date = Time.now)
          keys = Hash[keys]
          key_hash = Hash.new { |hash, key| hash[key] = [] }
          @object.gator_keys.each do | gk |
            if  keys[gk].kind_of?(Array)
              keys[gk].each do |k|
                key_hash[gk] = k
              end
            else
              key_hash[gk] = keys[gk]
            end
          end
          key_hash[:date] = normalize_date(date)
          return key_hash
        end
        
        # Create Group Key Hash
        def create_group_key_hash
          keys = []
          @object.gator_keys.each do | gk |
            keys << gk
          end
          keys << :date
          return keys
        end
        
        # Create Query Hash
        def create_query_hash(date = Time.now, grain, opts)
          key_hash = Hash.new { |hash, key| hash[key] = [] }
          # Set Keys
          @object.gator_keys.each do | gk |
            raise Errors::ModelNotSaved, "Missing key value #{gk}" if opts[gk].nil?
            if  opts[gk].kind_of?(Array)
              key_hash[gk] = {"$in" =>  opts[gk]}
            else
              key_hash[gk] = opts[gk]
            end
          end
          sdate,edate = convert_date_by_level(date,grain) # Set Dates
          key_hash[:date] = {"$gte" => normalize_date(sdate), "$lt" => normalize_date(edate)}
          return key_hash
        end
        
        # Normalize Dates
        def normalize_date(date)
          case date
          when String
            date =  Time.parse(date).change(:sec => 0).change(:min => 0)
          when Date
            date = date.to_time.change(:sec => 0).change(:min => 0)
          when Range
            date = normalize_date(date.change(:sec => 0).change(:min => 0).first)..normalize_date(date.change(:sec => 0).change(:min => 0).last)
          else
            date = date.change(:sec => 0).change(:min => 0)
          end
          return date.to_i
          
        end
          
      end  
    end
end