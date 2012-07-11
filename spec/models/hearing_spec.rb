require 'spec_helper'

describe Hearing do

  it { should belong_to(:case) }

  describe "create hearings with same hearing dates for same case" do
	it "should not create multiple hearings for the same date with the same case" do
      time = DateTime.now
      case1 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case1, :hearing_date => time)
	  FactoryGirl.create(:hearing, :case => case1, :hearing_date => time)
	  FactoryGirl.create(:hearing, :case => case1)

	  # need to expect exception
	  Hearing.count.should == 2
	end
  end

  describe "#matched_count" do
    it "returns # of cases matched" do
      
      #FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
      
      result = Hearing.matched_count
      result.should == 1
    end
  end
  describe "#unmatched_count" do
    it "returns # of cases unmatched" do
      
      FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
      FactoryGirl.create(:hearing)

      result = Hearing.unmatched_count
      result.should == 2
    end
  end
  describe "#pct_matched" do
    it "returns pct of matched hearings" do

      FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
      FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
      FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
      FactoryGirl.create(:hearing)
      
      result = Hearing.pct_matched
      result.should == 75.0
    end
  end

  describe "#status" do
  	it "should return the status of the hearing" do
  	 status = 'Status1'
  	 FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case), :hearing_status => status)
  	 FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case), :hearing_status => status)
  	 FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case), :hearing_status => 'Status2')
  	 Hearing.status.count.should == 2
  	end
  end

  describe "#date" do
  	
  	
  	describe "#date with dt value" do
  	  it "should return date value" do

	  	dt = DateTime.now
	  	hearing.date = dt
	  	hearing.date.should == dt
	  end
  	end
  	describe "#date - with nil date" do
	  it "should return min date value" do
	  	hearing = FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
	  	hearing.date = nil
	  	hearing.date.should == DateTime.new(0)
   	  end
    end
  end

end