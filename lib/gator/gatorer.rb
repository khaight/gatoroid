# encoding: utf-8
module Mongoid #:nodoc:
  module Gator
    class Gatorer
      include Readers

      # Initialize object
      def initialize(object, field)
        @object = object
        @for = field
        create_accessors
      end

      private

      # Return the total for a property of an object
      def total_for(date, grain, opts = {})
        unless date.nil?
          begin
           return  @object.class.where(create_query_hash(date, grain, opts)).sum(@for)
         rescue
           return  @object.where(create_query_hash(date, grain, opts)).sum(@for)
         end
        end
      end

      # Return the aggregate in a collection
      def collection_for(date, grain, opts = {})
        unless date.nil?
          return @object.collection.aggregate(create_pipeline(date, grain, opts))
        end
      end

      # Return collections for group
      def collection_for_group(date, grain, _off_set, opts = {})
        unless date.nil?
          pipeline = [
            { '$match' => create_query_hash(date, grain, opts) },
            { '$group' => create_group_key_hash },
            { '$project' => create_group_project_hash }
          ]
          return @object.collection.aggregate(pipeline)
        end
      end

      # Create pipline
      def create_pipeline(date, grain, opts = {})
        # group & project
        case grain
        when HOUR
          pipeline = [
            { '$match' => create_query_hash(date, grain, opts) },
            { '$group' => { '_id' => { 'year' => { '$year' => '$date' }, 'month' => { '$month' => '$date' }, 'day' => { '$dayOfMonth' => '$date' }, 'hour' => { '$hour' => '$date' } }, @for.to_s => { '$sum' => "$#{@for}" } } },
            { '$project' => { '_id' => 0, 'year' => '$_id.year', 'month' => '$_id.month', 'day' => '$_id.day', 'hour' => '$_id.hour', @for.to_s => 1 } }
          ]
        when DAY
          pipeline = [
            { '$match' => create_query_hash(date, grain, opts) },
            { '$group' => { '_id' => { 'year' => { '$year' => '$date' }, 'month' => { '$month' => '$date' }, 'day' => { '$dayOfMonth' => '$date' }, 'hour' => { '$hour' => '$date' } }, @for.to_s => { '$sum' => "$#{@for}" } } },
            { '$project' => { '_id' => 0, 'year' => '$_id.year', 'month' => '$_id.month', 'day' => '$_id.day', 'hour' => '$_id.hour', @for.to_s => 1 } }
          ]
        when MONTH
          pipeline = [
            { '$match' => create_query_hash(date, grain, opts) },
            { '$group' => { '_id' => { 'year' => { '$year' => '$date' }, 'month' => { '$month' => '$date' }, 'day' => { '$dayOfMonth' => '$date' }, 'hour' => { '$hour' => '$date' } }, @for.to_s => { '$sum' => "$#{@for}" } } },
            { '$project' => { '_id' => 0, 'year' => '$_id.year', 'month' => '$_id.month', 'day' => '$_id.day', 'hour' => '$_id.hour', @for.to_s => 1 } }
          ]
          end
        pipeline
      end

      # Create group project Hash
      def create_group_project_hash
        key_hash = Hash.new { |hash, key| hash[key] = [] }
        key_hash['_id'] = 0
        @object.gator_keys.each do |gk|
          key_hash[gk] = "$_id.#{gk}"
        end
        key_hash[@for] = 1
        key_hash
      end

      # Convert date levels
      def convert_date_by_level(date, level)
        if date.is_a?(Range)
          sdate = date.first
          edate = date.last
        else
          sdate = date
          edate = date
        end
        case level
        when HOUR
          return sdate.change(sec: 0), edate.change(sec: 0)
        when DAY
          return sdate.change(hour: 0).change(sec: 0), edate.change(hour: 0).change(sec: 0) + 1.day
        when MONTH
          return sdate.change(day: 1).change(hour: 0).change(sec: 0), edate.change(day: 1).change(hour: 0).change(sec: 0) + 1.month
        end
      end

      # Create fkey
      def create_fkey(_grain, _off_set)
        fkey = Javascript.aggregate_hour
        fkey
      end

      protected

      def create_accessors
        self.class.class_eval do
          define_method :inc  do |*args|
            keys, date = gen_params(Hash[*args])
            inc_counter(keys, date)
          end

          define_method :dec do |*args|
            keys, date = gen_params(Hash[*args])
            dec_counter(keys, date)
          end

          define_method :add do |how_many, *args|
            keys, date = gen_params(Hash[*args])
            add_to_counter(how_many, keys, date)
          end

          define_method :reset do |*args|
            keys, date = gen_params(Hash[*args])
            reset_counter(keys, date)
          end
        end
      end

      # Add
      def add_to_counter(how_much = 1, keys = [], date = Time.now)
        return if how_much == 0
        # Upsert value
        begin
           # Upsert value
           @object.collection.find(create_key_hash(keys, date)).update_one(
             { '$inc' => {
               @for.to_s => how_much
             } },
             upsert: true
           )
         rescue Exception => e
           puts e.inspect
         end
      end

      # Reset Counter
      def reset_counter(keys = [], date = Time.now)
        # Upsert value
        @object.collection.find(create_key_hash(keys, date)).update_one(
          { '$set' => {
            @for.to_s => 0
          } },
          upsert: true
        )
      end

      # Increment Counter
      def inc_counter(keys, date = Time.now)
        add_to_counter(1, keys, date)
      end

      # Decrement Counter
      def dec_counter(keys, date = Time.now)
        add_to_counter(-1, keys, date)
      end

      # Generate parameters
      def gen_params(params)
        date = Time.now # Set default date to now
        key_hash = Hash.new { |hash, key| hash[key] = [] }
        @object.gator_keys.each do|gk|
          fail Errors::ModelNotSaved, "Missing key value #{gk}" if params[gk].nil?
          key_hash[gk] = params[gk]
        end
        # Set Date
        date = params[:date] unless params[:date].nil?
        [key_hash, date]
      end

      # Create Hash Key
      def create_key_hash(keys, date = Time.now)
        keys = Hash[keys]
        key_hash = Hash.new { |hash, key| hash[key] = [] }
        @object.gator_keys.each do |gk|
          if keys[gk].is_a?(Array)
            keys[gk].each do |k|
              key_hash[gk] = k
            end
          else
            key_hash[gk] = keys[gk]
          end
        end
        key_hash[:date] = normalize_date(date)
        key_hash.inject({}) { |symb, (k, v)| symb[k.to_sym] = v; symb }
      end

      # Create Group Key Hash
      def create_group_key_hash
        key_hash = Hash.new { |hash, key| hash[key] = [] }

        key_hash['_id'] = {}
        @object.gator_keys.each do |gk|
          key_hash['_id'][gk.to_s] = { '$toLower' => "$#{gk}" }
        end
        key_hash[@for] = { '$sum' => "$#{@for}" }
        key_hash
      end

      # Create Query Hash
      def create_query_hash(date = Time.now, grain, opts)
        key_hash = Hash.new { |hash, key| hash[key] = [] }
        # Set Keys
        unless opts.empty?
          @object.gator_keys.each do |gk|
            next if opts[gk].nil?
            key_hash[gk] = if opts[gk].is_a?(Array)
                             { '$in' => opts[gk] }
                           else
                             opts[gk]
            end
          end
        end

        sdate, edate = convert_date_by_level(date, grain) # Set Dates
        key_hash[:date] = { '$gte' => normalize_date(sdate), '$lte' => normalize_date(edate) }
        key_hash
      end

      # Normalize Dates
      def normalize_date(date)
        case date
        when String
          date = Time.parse(date).change(sec: 0).change(min: 0)
        when Date
          date = date.to_time.change(sec: 0).change(min: 0)
        when Range
          date = normalize_date(date.change(sec: 0).change(min: 0).first)..normalize_date(date.change(sec: 0).change(min: 0).last)
        else
          date = date.change(sec: 0).change(min: 0)
        end
        date.utc
      end
    end
  end
end
