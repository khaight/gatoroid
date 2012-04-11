# encoding: utf-8
module Mongoid  #:nodoc:
  module Gator
      module Readers

        HOUR = "HOUR"
        DAY = "DAY"
        MONTH = "MONTH"
        DEFAULT_GRAIN = DAY
      
        # Today - Gets total for today on DAY level
        def today(opts={})
          total_for(Time.now, DEFAULT_GRAIN, opts).to_i
        end
      
        # Yesterday - Gets total for tomorrow on DAY level
        def yesterday(opts={})
          total_for(Time.now - 1.day, DEFAULT_GRAIN,opts).to_i
        end

        # On - Gets total for a specified day on DAY level
        def on(date,opts={})
          total_for(date, DEFAULT_GRAIN,opts).to_i
        end

        # Range - retuns a collection for a specified range on specified level
        def range(date, grain=DEFAULT_GRAIN, opts={})
            collection_for(date,grain,opts)
        end
      
      end
  end
end