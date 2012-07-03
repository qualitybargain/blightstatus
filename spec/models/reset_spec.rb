require 'spec_helper'

describe Reset do
  it { should belong_to(:case) }

  before(:each) do
    @case = FactoryGirl.create(:case)
  end

  it "should not create multiple resets with the same date" do
    time = Time.now
    c = FactoryGirl.build(:case)

    Reset.create(:case_number => c.case_number, :reset_date => time)
    Reset.create(:case_number => c.case_number, :reset_date => time)

    Reset.count.should eq 1
  end
  describe "#date -> empty date" do
  	it "#date" do
	  r = FactoryGirl.create(:reset, :reset_date => nil)
	  r.date.should == DateTime.new(0)
	end
  end
  describe "#date -> reset_date" do
  	it "#date" do
  	  dt = DateTime.now
	  r = FactoryGirl.build(:reset, :reset_date => dt)
	  r.date.should == dt
	end
  end
  
  describe "#matched_count" do
  	it "matched resets should equal 1" do
  	  FactoryGirl.create(:reset, :case => @case)
  	  FactoryGirl.create(:reset)
  	  FactoryGirl.create(:reset)
	  Reset.matched_count.should == 1
	end
  end

  describe "#unmatched_count" do
  	it "unmatched resets should equal 2" do
  	  FactoryGirl.create(:reset, :case => @case)
  	  FactoryGirl.create(:reset)
  	  FactoryGirl.create(:reset)
	  Reset.unmatched_count.should == 2
	end
  end

  describe "#pct_matched" do
  	it "matched resets should equal 2" do
  	  FactoryGirl.create(:reset, :case => @case)
  	  FactoryGirl.create(:reset, :case => @case)
  	  FactoryGirl.create(:reset, :case => @case)
  	  FactoryGirl.create(:reset)
  	  FactoryGirl.create(:reset)
	  Reset.pct_matched.should == 60
	end
  end
end
