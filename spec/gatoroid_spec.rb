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
    Time.zone = 'UTC'
  end

  it 'should expose the same version as the VERSION file' do
    expect(Mongoid::Gator::VERSION).to eq('2.0')
  end

  it 'should not raise errors when using to/as_json' do
    mock = Test.new(siteid: 1000)
    json_as = {}
    json_to = ''

    expect do
      json_as = mock.as_json(except: :_id)
      json_to = mock.to_json(except: :_id)
    end.not_to raise_error
    expect(json_as).to eq('siteid' => 1000)
    expect(json_to).to eq('{"siteid":1000}')
  end

  describe 'when using an instance of the object' do
    before(:all) do
      @obj = Test.new
      @multi_obj = MultiField.new
    end

    it 'should deny access to undefined methods' do
      expect { @obj.test_method }.to raise_error NoMethodError
      expect { @obj.test_method = {} }.to raise_error NoMethodError
    end

    it 'should create a method for gator_fields' do
      expect(@obj.respond_to?(:visits)).to eq(true)
    end

    it 'should NOT create an index for the gator_fields' do
      expect(@obj.class.index_specifications).to_not include(:visits)
    end

    it 'should create a method for accesing the stats of the proper class' do
      expect(@obj.visits.class).to eq(Mongoid::Gator::Gatorer)
    end

    it 'should create an array in the class with all gator fields' do
      expect(@obj.class.gator_fields).to eq([:visits])
    end

    it 'should create an array in the class with all gator fields even when monkey patching' do
      class Test
        gator_field :something_else
      end
      expect(@obj.class.gator_fields).to eq([:visits, :something_else])
    end

    it 'should not increment stats when missing key' do
      expect { @obj.visits.inc }.to raise_error Mongoid::Errors::ModelNotSaved
    end

    it 'should increment stats when key is present' do
      expect { @obj.visits.inc(siteid: 100) }.not_to raise_error
    end

    it 'should not decrement stats when key is present' do
      expect { @obj.visits.dec }.to raise_error Mongoid::Errors::ModelNotSaved
    end

    it 'should decrement stats when key is present' do
      expect { @obj.visits.dec(siteid: 100) }.not_to raise_error
    end

    it 'should not add stats when key is present' do
      expect { @obj.visits.add(1) }.to raise_error Mongoid::Errors::ModelNotSaved
    end

    it 'should add stats when key is present' do
      expect { @obj.visits.add(1, siteid: 100) }.not_to raise_error
    end

    it 'should give 1 for today stats', today_test: true do
      expect { @obj.visits.add(1, siteid: 100) }.not_to raise_error
      expect(@obj.visits.today(siteid: 100)).to eq(1)
    end

    it 'should give 1 for yesterday stats' do
      expect { @obj.visits.add(1, siteid: 100, date: Time.now - 1.day) }.not_to raise_error
      expect(@obj.visits.yesterday(siteid: 100)).to eq(1)
    end

    it 'should give 1 for using on for today stats' do
      expect { @obj.visits.add(1, siteid: 100) }.not_to raise_error
      expect(@obj.visits.on(Time.now, siteid: 100)).to eq(1)
    end

    it 'should give 1 for last stats' do
      expect { @obj.visits.add(1, siteid: 100, date: Time.now - 6.day) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 100, date: Time.now - 5.day) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 100, date: Time.now - 4.day) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 100, date: Time.now - 3.day) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 100, date: Time.now - 2.day) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 100, date: Time.now - 1.day) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 100) }.not_to raise_error
      expect(@obj.visits.last(7, siteid: 100)).to eq(7)
    end

    it 'should have 1 record using range method for today and yesterday at day grain', grain_tests_day: true do
      expect { @obj.visits.add(100, siteid: 100) }.not_to raise_error
      1.upto(365) do |x|
        @obj.visits.add(1, siteid: 100, date: Time.now + x.days)
      end
      expect(@obj.visits.range(Time.zone.now..Time.zone.now + 365.day, Mongoid::Gator::Readers::DAY, siteid: 100).length).to eq(366)
    end

    it 'should have 1 record using range method for today and yesterday at hour grain', grain_tests: true do
      Time.zone = 'Pacific Time (US & Canada)'
      1.upto(1) do |x|
        0.upto(23) do |y|
          @obj.visits.add(1, siteid: 100, date: Time.zone.now + x.days + y.hours)
        end
      end

      expect(@obj.visits.range(Time.zone.now..Time.zone.now + 365.day, Mongoid::Gator::Readers::HOUR, siteid: 100).length).to eq(8761)
    end

    it 'should have 1 record using range method for today and yesterday at MONTH grain', grain_tests: true do
      Time.zone = 'Pacific Time (US & Canada)'
      1.upto(1) do |x|
        0.upto(23) do |y|
          @obj.visits.add(1, siteid: 100, date: Time.zone.now + x.days + y.hours)
        end
      end
      expect(@obj.visits.range(Time.zone.now..Time.zone.now + 365.day, Mongoid::Gator::Readers::MONTH, siteid: 100).length).to eq(13)
    end

    it 'should reset value to zero' do
      expect { @obj.visits.reset(date: Time.now, siteid: 100) }.not_to raise_error
      expect(@obj.visits.today(siteid: 100)).to eq(0)
    end

    it 'should have 1 record using range method for today and yesterday at day grain', group_by: true do
      expect { @obj.visits.add(1, siteid: 100) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 200) }.not_to raise_error
      expect { @obj.visits.add(1, siteid: 200) }.not_to raise_error
      expect(@obj.visits.group_by(Time.now..Time.now + 1.day, Mongoid::Gator::Readers::DAY).length).to eq(2)
    end
  end

  describe 'when using as a model' do
    it 'should deny access to undefined methods' do
      expect { Test.test_method }.to raise_error NoMethodError
      expect { Test.test_method = {} }.to raise_error NoMethodError
    end

    it 'should create a method for gator_fields' do
      expect(Test.respond_to?(:visits)).to eq(true)
    end

    it 'should NOT create an index for the gator_fields' do
      expect(Test.index_specifications).to_not include(:visits)
    end

    it 'should create a method for accesing the stats of the proper class' do
      expect(Test.visits.class).to eq(Mongoid::Gator::Gatorer)
    end

    it 'should create an array in the class with all gator fields even when monkey patching' do
      expect(Test.gator_fields).to  eq([:visits, :something_else])
    end

    it 'should not increment stats when missing key' do
      expect { Test.visits.inc }.to raise_error Mongoid::Errors::ModelNotSaved
    end

    it 'should increment stats when key is present' do
      expect { Test.visits.inc(siteid: 200) }.not_to raise_error
    end

    it 'should not decrement stats when key is present' do
      expect { Test.visits.dec }.to raise_error Mongoid::Errors::ModelNotSaved
    end

    it 'should decrement stats when key is present' do
      expect { Test.visits.dec(siteid: 200) }.not_to raise_error
    end

    it 'should not add stats when key is present' do
      expect { Test.visits.add(1) }.to raise_error Mongoid::Errors::ModelNotSaved
    end

    it 'should add stats when key is present' do
      expect { Test.visits.add(1, siteid: 200) }.not_to raise_error
    end

    it 'should give 1 for today stats' do
      expect { Test.visits.add(1, siteid: 200) }.not_to raise_error
      expect(Test.visits.today(siteid: 200)).to eq(1)
    end

    it 'should give 0 for yesterday stats' do
      expect(Test.visits.yesterday(siteid: 200)).to eq(0)
    end

    it 'should give 1 for using ON for today stats' do
      expect { Test.visits.add(1, siteid: 200) }.not_to raise_error
      expect(Test.visits.on(Time.now, siteid: 200)).to eq(1)
    end

    it 'should give 1 for last stats' do
      expect { Test.visits.add(1, siteid: 200, date: Time.now - 6.days) }.not_to raise_error
      expect { Test.visits.add(1, siteid: 200, date: Time.now - 5.days) }.not_to raise_error
      expect { Test.visits.add(1, siteid: 200, date: Time.now - 4.days) }.not_to raise_error
      expect { Test.visits.add(1, siteid: 200, date: Time.now - 3.days) }.not_to raise_error
      expect { Test.visits.add(1, siteid: 200, date: Time.now - 2.days) }.not_to raise_error
      expect { Test.visits.add(1, siteid: 200, date: Time.now - 1.days) }.not_to raise_error
      expect { Test.visits.add(1, siteid: 200) }.not_to raise_error
      expect(Test.visits.last(7, siteid: 200)).to eq(7)
    end

    it 'should reset value to zero' do
      expect { Test.visits.reset(date: Time.now, siteid: 200) }.not_to raise_error
      expect(Test.visits.today(siteid: 200)).to eq(0)
    end

    it 'should have 1 record using range method for today and yesterday at day grain', test: true do
      expect { MultiField.visits.add(1, siteid: 100, req_type: 'web') }.not_to raise_error
      expect { MultiField.visits.add(1, siteid: 200, req_type: 'mobile') }.not_to raise_error
      expect { MultiField.visits.add(1, siteid: 100, req_type: 'mobile') }.not_to raise_error
      expect(MultiField.visits.group_by(Time.now..Time.now + 1.day, Mongoid::Gator::Readers::DAY).length).to eq(3)
    end
  end
end
