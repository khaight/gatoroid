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
          total_for(Time.zone.now, DEFAULT_GRAIN, opts).to_i
        end

        # Yesterday - Gets total for tomorrow on DAY level
        def yesterday(opts={})
          total_for(Time.zone.now - 1.day, DEFAULT_GRAIN,opts).to_i
        end

        # On - Gets total for a specified day on DAY level
        def on(date,opts={})
          total_for(date, DEFAULT_GRAIN,opts).to_i
        end
        
        def last(total_days = 7,opts={})
          total_for((Time.zone.now - total_days.days)..Time.zone.now, DEFAULT_GRAIN, opts).to_i
        end

        # Range - retuns a collection for a specified range on specified level
        def range(date, grain=DEFAULT_GRAIN, opts={})
            # Get Offset
            if date.is_a?(Range)
                off_set = date.first.utc_offset
            else
                off_set = date.utc_offset
            end


            data = collection_for(date,grain,off_set,opts)

            # Add Zero values for dates missing
            # May want to look into a way to get mongo to do this
            if date.is_a?(Range)
              start_date = date.first
              end_date = date.last

              case grain
                when HOUR
                  start_date = start_date.change(:sec=>0).change(:min => 0)
                  end_date = end_date.change(:sec=>0).change(:min => 0) - 1.hour
                when DAY
                  start_date = start_date.change(:hour=>0).change(:sec=>0).change(:min => 0)
                  end_date = end_date.change(:hour=>0).change(:sec=>0).change(:min => 0)
                when MONTH
                  start_date = start_date.change(:day=>1).change(:hour=>0).change(:sec=>0).change(:min => 0)
                  end_date = end_date.change(:day=>1).change(:hour=>0).change(:sec=>0).change(:min => 0)
              end

              while start_date <= end_date
                if data.select{|item| item['date'].to_i == start_date.to_i}.first.nil?
                    data << {"date" => "#{start_date.to_i}", @for => 0}
                end
                
                case grain
                  when HOUR
                    start_date = start_date + 1.hour
                  when DAY
                    start_date = start_date + 1.day
                  when MONTH
                    start_date = start_date + 1.month
                end
              end
            end
            # Sort by date
            data = data.sort_by { |hsh| hsh["date"] }
            return data
        end
        
        
        # Group_by - retuns a collection for a specific key
        def group_by(date,grain,opts={})
            # Get Offset
            if date.is_a?(Range)
                off_set = date.first.utc_offset
            else
                off_set = date.utc_offset
            end
            data = collection_for_group(date,grain,off_set,opts)
            return data
        end
        
      end
  end
end
