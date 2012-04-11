require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Test 
  include Mongoid::Gator
  field :siteid
  gator_field :visits   # Dummy field
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
  
  describe "when creating a new field with stats" do
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
      
      it "should not update stats when missing key" do
        lambda { @obj.visits.inc }.should raise_error Mongoid::Errors::ModelNotSaved
      end
      
      it "should not update stats when key is present" do
        lambda { @obj.visits.inc(:siteid=>100) }.should_not raise_error Mongoid::Errors::ModelNotSaved
      end

      it "should give 1 for today stats" do
        @obj.visits.today(:siteid=>100).should == 1
      end
      
      it "should give 0 for today stats" do
        @obj.visits.yesterday(:siteid=>100).should == 0
      end
      

  end

end