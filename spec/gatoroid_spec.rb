require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Test 
  include Mongoid::Gator
  field :siteid
  gator_field :visits
end


describe Mongoid::Gator do
  before(:all) do
    @gatoroid_version = File.read(File.expand_path("../VERSION", File.dirname(__FILE__)))
  end

  it "should expose the same version as the VERSION file" do
    Mongoid::Gator::VERSION.should == @gatoroid_version
  end
  
  it "should not raise errors when using to/as_json" do
      mock = Test.new(:siteid => 1000)
      json_as = {}
      json_to = ""

      lambda {
        json_as = mock.as_json(:except => :_id)
        json_to = mock.to_json(:except => :_id)
      }.should_not raise_error
      json_as.should == { "siteid" => 1000 }
      json_to.should == "{\"siteid\":1000}"
  end
  
  describe "when using an instance of the object" do
      before(:all) do
        @obj = Test.new
      end
      
      it "should deny access to undefined methods" do
        lambda { @obj.test_method }.should raise_error NoMethodError
        lambda { @obj.test_method = {} }.should raise_error NoMethodError
      end
      
      it "should create a method for gator_fields" do
        @obj.respond_to?(:visits).should be_true
      end
      
      it "should NOT create an index for the gator_fields" do
        @obj.class.index_options.should_not include(:visits)
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
        lambda { @obj.visits.inc(:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should not decrement stats when key is present" do
        lambda { @obj.visits.dec() }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should decrement stats when key is present" do
        lambda { @obj.visits.dec(:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should not add stats when key is present" do
        lambda { @obj.visits.add(1) }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should add stats when key is present" do
        lambda { @obj.visits.add(1,:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
      end


      it "should give 1 for today stats" do
        lambda { @obj.visits.add(1,:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        @obj.visits.today(:siteid=>100).should == 1
      end
      
      it "should give 1 for yesterday stats" do
        lambda { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 1.day) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        @obj.visits.yesterday(:siteid=>100).should == 1
      end
      
      it "should give 1 for using on for today stats" do
        lambda { @obj.visits.add(1,:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        @obj.visits.on(Time.now,:siteid=>100).should == 1
      end
      
      it "should give 1 for last stats" do
        lambda { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 6.day) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 5.day) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 4.day) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 3.day) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 2.day) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>100, :date=>Time.now - 1.day) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        @obj.visits.last(7,:siteid=>100).should == 7
      end
      
      it "should have 1 record using range method for today and yesterday at day grain" do
        @obj.visits.range(Time.now..Time.now + 1.day,Mongoid::Gator::Readers::DAY, :siteid=>100).should have(2).record
      end
      
      it "should have 1 record using range method for today and yesterday at hour grain" do
        @obj.visits.range(Time.now.change(:hour=>0).change(:sec=>0)..Time.now.change(:hour=>0).change(:sec=>0) + 1.day,Mongoid::Gator::Readers::HOUR, :siteid=>100).should have(24).record
      end
      
      it "should have 1 record using range method for today and yesterday at month grain" do
        @obj.visits.range(Time.now..Time.now + 1.day,Mongoid::Gator::Readers::MONTH, :siteid=>100).should have(1).record
      end
      
      it "should reset value to zero" do
        @obj.visits.reset(:date => Time.now, :siteid=>100).should_not raise_error Mongoid::Errors::ModelNotSaved
        @obj.visits.today(:siteid=>100).should == 0
      end
      
      it "should have 1 record using range method for today and yesterday at day grain", :test => true do
        lambda { @obj.visits.add(1,:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { @obj.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
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
         Test.index_options.should_not include(:visits)
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
        lambda { Test.visits.inc(:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should not decrement stats when key is present" do
        lambda { Test.visits.dec() }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should decrement stats when key is present" do
        lambda { Test.visits.dec(:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should not add stats when key is present" do
        lambda { Test.visits.add(1) }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should add stats when key is present" do
        lambda { Test.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
      end

      it "should give 1 for today stats" do
        lambda { Test.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        Test.visits.today(:siteid=>200).should == 1
      end

      it "should give 0 for yesterday stats" do
        Test.visits.yesterday(:siteid=>200).should == 0
      end

      it "should give 1 for using ON for today stats" do
        lambda { Test.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        Test.visits.on(Time.now,:siteid=>200).should == 1
      end
      
      it "should give 1 for last stats" do
        lambda { Test.visits.add(1,:siteid=>200, :date => Time.now - 6.days) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200, :date => Time.now - 5.days) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200, :date => Time.now - 4.days) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200, :date => Time.now - 3.days) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200, :date => Time.now - 2.days) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200, :date => Time.now - 1.days) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        Test.visits.last(7,:siteid=>200).should ==7
      end

      it "should have 1 record using range method for today and yesterday at day grain" do
        Test.visits.range(Time.now..Time.now + 1.day,Mongoid::Gator::Readers::DAY, :siteid=>200).should have(2).record
      end

      it "should have 1 record using range method for today and yesterday at hour grain" do
        Test.visits.range(Time.now.change(:hour=>0).change(:sec=>0)..Time.now.change(:hour=>0).change(:sec=>0) + 1.day,Mongoid::Gator::Readers::HOUR, :siteid=>200).should have(24).record
      end

      it "should have 1 record using range method for today and yesterday at month grain" do
        Test.visits.range(Time.now.change(:hour=>0).change(:sec=>0)..Time.now.change(:hour=>0).change(:sec=>0) + 1.day,Mongoid::Gator::Readers::HOUR, :siteid=>200).should have(24).record
      end
      
      it "should reset value to zero" do
        Test.visits.reset(:date => Time.now, :siteid=>200).should_not raise_error Mongoid::Errors::ModelNotSaved
        Test.visits.today(:siteid=>200).should == 0
      end
      
      it "should have 1 record using range method for today and yesterday at day grain", :test => true do
        lambda { Test.visits.add(1,:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        lambda { Test.visits.add(1,:siteid=>200) }.should_not raise_error Mongoid::Errors::ModelNotSaved
        Test.visits.group_by(Time.now..Time.now + 1.day,Mongoid::Gator::Readers::DAY).should have(2).record
      end
      
   end

end