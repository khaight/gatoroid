require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Test 
  include Mongoid::Gator
  field :siteid
  gator_field :visits
end

class MultiField 
  include Mongoid::Gator
  field :siteid
  field :req_type
  gator_field :visits
end


describe Mongoid::Gator do
  before(:all) do
    @gatoroid_version = File.read(File.expand_path("../VERSION", File.dirname(__FILE__)))
    Time.zone = 'UTC'
  end

  it "should expose the same version as the VERSION file" do
    Mongoid::Gator::VERSION.should == @gatoroid_version
  end
  
  it "should not raise errors when using to/as_json" do
      mock = Test.new(:siteid => 1000)
      json_as = {}
      json_to = ""

      expect {
        json_as = mock.as_json(:except => :_id)
        json_to = mock.to_json(:except => :_id)
      }.not_to raise_error
      json_as.should == { "siteid" => 1000 }
      json_to.should == "{\"siteid\":1000}"
  end
  
  describe "when using an instance of the object" do
      before(:all) do
        @obj = Test.new
        @multi_obj = MultiField.new
      end
      
      it "should deny access to undefined methods" do
        lambda { @obj.test_method }.should raise_error NoMethodError
        lambda { @obj.test_method = {} }.should raise_error NoMethodError
      end
      
      it "should create a method for gator_fields" do
        @obj.respond_to?(:visits).should be_true
      end
      
      it "should NOT create an index for the gator_fields" do
        @obj.class.index_specifications.should_not include(:visits)
      end
      
      it "should create a method for accesing the stats of the proper class" do
        @obj.visits.class.should == Mongoid::Gator::Gatorer
      end
      
      it "should create an array in the class with all gator fields" do
        @obj.class.gator_fields.should == [ :visits ]
      end
      
      it "should create an array in the class with all gator fields even when monkey patching" do
        class Test
             gator_field :something_else
        end
        @obj.class.gator_fields.should == [ :visits, :something_else ]
      end
      
      it "should not increment stats when missing key" do
        lambda { @obj.visits.inc }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should increment stats when key is present" do
        expect { @obj.visits.inc(:siteid=>100) }.not_to raise_error
      end
      
      it "should not decrement stats when key is present" do
        lambda { @obj.visits.dec() }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should decrement stats when key is present" do
        expect { @obj.visits.dec(:siteid=>100) }.not_to raise_error
      end
      
      it "should not add stats when key is present" do
        lambda { @obj.visits.add(1) }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should add stats when key is present" do
        expect { @obj.visits.add(1,:siteid=>100) }.not_to raise_error
      end


      it "should give 1 for today stats", :today_test => true do
        expect { @obj.visits.add(1,:siteid=>100) }.not_to raise_error
        @obj.visits.today(:siteid=>100).should == 1
      end
      
      it "should give 1 for yesterday stats" do
        expect { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 1.day) }.not_to raise_error
        @obj.visits.yesterday(:siteid=>100).should == 1
      end
      
      it "should give 1 for using on for today stats" do
        expect { @obj.visits.add(1,:siteid=>100) }.not_to raise_error
        @obj.visits.on(Time.now,:siteid=>100).should == 1
      end
      
      it "should give 1 for last stats" do
        expect { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 6.day) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 5.day) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 4.day) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 3.day) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 2.day) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 1.day) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>100) }.not_to raise_error
        @obj.visits.last(7,:siteid=>100).should == 7
      end
      
      it "should have 1 record using range method for today and yesterday at day grain", :grain_tests_day => true do
        expect { @obj.visits.add(100,:siteid=>100) }.not_to raise_error
        1.upto(365){ | x |            
            @obj.visits.add(1,:siteid=>100, :date=>Time.now + x.days) 
        }
        @obj.visits.range(Time.zone.now..Time.zone.now + 365.day,Mongoid::Gator::Readers::DAY, :siteid=>100).should have(366).record
      end
      
      it "should have 1 record using range method for today and yesterday at hour grain", :grain_tests => true do
        Time.zone = "Pacific Time (US & Canada)"
        1.upto(1){ | x |  
          0.upto(23){ |y| 
            @obj.visits.add(1,:siteid=>100, :date=>Time.zone.now + x.days + y.hours )
            
          }
        }
        
        @obj.visits.range(Time.zone.now..Time.zone.now + 365.day,Mongoid::Gator::Readers::HOUR, :siteid=>100).should have(24).record
      end
      
      it "should have 1 record using range method for today and yesterday at MONTH grain", :grain_tests => true do
        Time.zone = "Pacific Time (US & Canada)"
        1.upto(1){ | x |  
          0.upto(23){ |y| 
            @obj.visits.add(1,:siteid=>100, :date=>Time.zone.now + x.days + y.hours )
            
          }
        }
        
        @obj.visits.range(Time.zone.now..Time.zone.now + 365.day,Mongoid::Gator::Readers::MONTH, :siteid=>100).should have(1).record
      end
      
      it "should reset value to zero" do
        expect {@obj.visits.reset(:date => Time.now, :siteid=>100)}.not_to raise_error
        @obj.visits.today(:siteid=>100).should == 0
      end
      
      it "should have 1 record using range method for today and yesterday at day grain", :group_by => true do
        expect { @obj.visits.add(1,:siteid=>100) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>200) }.not_to raise_error
        expect { @obj.visits.add(1,:siteid=>200) }.not_to raise_error
        @obj.visits.group_by(Time.now..Time.now + 1.day,Mongoid::Gator::Readers::DAY).should have(2).record
      end
      
  end
  
  
  describe "when using as a model" do
       it "should deny access to undefined methods" do
         lambda { Test.test_method }.should raise_error NoMethodError
         lambda { Test.test_method = {} }.should raise_error NoMethodError
       end

       it "should create a method for gator_fields" do
         Test.respond_to?(:visits).should be_true
       end

       it "should NOT create an index for the gator_fields" do
         Test.index_specifications.should_not include(:visits)
       end

       it "should create a method for accesing the stats of the proper class" do
         Test.visits.class.should == Mongoid::Gator::Gatorer
       end

       it "should create an array in the class with all gator fields even when monkey patching" do
         Test.gator_fields.should == [ :visits, :something_else ]
       end

      it "should not increment stats when missing key" do
        lambda { Test.visits.inc }.should raise_error Mongoid::Errors::ModelNotSaved
      end

      it "should increment stats when key is present" do
        expect { Test.visits.inc(:siteid=>200) }.not_to raise_error
      end
      
      it "should not decrement stats when key is present" do
        lambda { Test.visits.dec() }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should decrement stats when key is present" do
        expect { Test.visits.dec(:siteid=>200) }.not_to raise_error
      end
      
      it "should not add stats when key is present" do
        lambda { Test.visits.add(1) }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should add stats when key is present" do
        expect { Test.visits.add(1,:siteid=>200) }.not_to raise_error
      end

      it "should give 1 for today stats" do
        expect { Test.visits.add(1,:siteid=>200) }.not_to raise_error
        Test.visits.today(:siteid=>200).should == 1
      end

      it "should give 0 for yesterday stats" do
        Test.visits.yesterday(:siteid=>200).should == 0
      end

      it "should give 1 for using ON for today stats" do
        expect { Test.visits.add(1,:siteid=>200) }.not_to raise_error
        Test.visits.on(Time.now,:siteid=>200).should == 1
      end
      
      it "should give 1 for last stats" do
        expect { Test.visits.add(1,:siteid=>200, :date => Time.now - 6.days) }.not_to raise_error
        expect { Test.visits.add(1,:siteid=>200, :date => Time.now - 5.days) }.not_to raise_error
        expect { Test.visits.add(1,:siteid=>200, :date => Time.now - 4.days) }.not_to raise_error
        expect { Test.visits.add(1,:siteid=>200, :date => Time.now - 3.days) }.not_to raise_error
        expect { Test.visits.add(1,:siteid=>200, :date => Time.now - 2.days) }.not_to raise_error
        expect { Test.visits.add(1,:siteid=>200, :date => Time.now - 1.days) }.not_to raise_error
        expect { Test.visits.add(1,:siteid=>200) }.not_to raise_error
        Test.visits.last(7,:siteid=>200).should ==7
      end

      it "should reset value to zero" do
        expect {Test.visits.reset(:date => Time.now, :siteid=>200)}.not_to raise_error
        Test.visits.today(:siteid=>200).should == 0
      end
      
      it "should have 1 record using range method for today and yesterday at day grain", :test => true do
        expect { MultiField.visits.add(1,:siteid=>100, :req_type=>"web") }.not_to raise_error
        expect { MultiField.visits.add(1,:siteid=>200, :req_type=>"mobile") }.not_to raise_error
        expect { MultiField.visits.add(1,:siteid=>100, :req_type=>"mobile") }.not_to raise_error
        MultiField.visits.group_by(Time.now..Time.now + 1.day,Mongoid::Gator::Readers::DAY).should have(3).record
      end
      
   end

end