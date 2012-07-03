require 'spec_helper'

describe Demolition do
  before(:each) do
	@address = FactoryGirl.create(:address)
  end
  it { should belong_to(:case) }
  it { should belong_to(:address) }
  
  describe "#matched_count" do
   it "should return total # of demoltions assigned to an address" do
      FactoryGirl.create(:demolition, :address => @address)
      FactoryGirl.create(:demolition, :address => @address)
      FactoryGirl.create(:demolition)

      result = Demolition.matched_count
      result.should == 2
    end
  end

  describe "#unmatched_count" do
   it "should return total # of demoltions assigned to an address" do
      FactoryGirl.create(:demolition, :address => @address)
      FactoryGirl.create(:demolition)
      FactoryGirl.create(:demolition)

      result = Demolition.unmatched_count
      result.should == 2
    end
  end

  describe "#pct_matched" do
   it "should return total # of demoltions assigned to an address" do
      FactoryGirl.create(:demolition, :address => @address)
      FactoryGirl.create(:demolition)
      FactoryGirl.create(:demolition, :address => @address)
      FactoryGirl.create(:demolition)
      FactoryGirl.create(:demolition)

      result = Demolition.pct_matched
      result.should == 40.0
    end
  end
  describe "#date -> date_started" do
   it "should return date_started of demoliton as date" do
   		dt = DateTime.now - 2.days
      d = FactoryGirl.build(:demolition, :date_started => dt)
      result = d.date
      result.should == dt
    end
  end

  describe "#date -> date_created" do
   it "should return date_completed  of demolition as date" do
   		dt = DateTime.now - 1.days
      d = FactoryGirl.build(:demolition, :date_completed => dt)
      result = d.date
      result.should == dt
    end
  end

  describe "#date -> date_created" do
   it "should return DateTime.new(0)  of demolition as date" do
      d = FactoryGirl.build(:demolition)
      result = d.date
      result.should == DateTime.new(0)
    end
  end
end
