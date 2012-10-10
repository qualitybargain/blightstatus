require 'spec_helper'

describe Hearing do

  it { should belong_to(:case) }

  before(:each) do
    @hearing = FactoryGirl.create(:hearing,:case => FactoryGirl.create(:case))
  end

  describe "create hearings with same hearing dates for same case" do
  	it "should not create multiple hearings for the same date with the same case" do
      time = DateTime.now
      case1 = FactoryGirl.create(:case)
      FactoryGirl.create(:hearing, :case => case1)
      FactoryGirl.create(:hearing, :case => case1, :hearing_date => time)

      lambda { FactoryGirl.create(:hearing, :case => case1, :hearing_date => time) }.should raise_error(ActiveRecord::RecordInvalid, /already been taken/)
  	  Hearing.count.should == 3
  	end
  end

  describe ".past_incomplete" do
    it "returns hearings which are incomplete and in the past" do
      Hearing.past_incomplete.length.should eq(0)

      @hearing.update_attributes(:is_complete => false, :hearing_date => Time.now - 3.weeks)
      Hearing.past_incomplete.should include(@hearing)
      Hearing.past_incomplete.length.should eq(1)
    end
  end

  describe ".clear_incomplete" do
    it "deletes hearings which are not complete and which are in the past" do
      @hearing.update_attributes(:is_complete => false, :hearing_date => Time.now - 3.weeks)
      FactoryGirl.create(:hearing)
      Hearing.past_incomplete.length.should eq(1)

      Hearing.clear_incomplete
      Hearing.past_incomplete.length.should eq(0)
    end
  end

  describe ".matched_count" do
    it "returns # of cases matched" do
      FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
      FactoryGirl.create(:hearing)
      result = Hearing.matched_count
      result.should == 2
    end
  end
  describe ".unmatched_count" do
    it "returns # of cases unmatched" do
      FactoryGirl.create(:hearing)
      FactoryGirl.create(:hearing)

      result = Hearing.unmatched_count
      result.should == 2
    end
  end
  describe ".pct_matched" do
    it "returns pct of matched hearings" do

      3.times do |i|
        FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case))
      end
      FactoryGirl.create(:hearing)

      result = Hearing.pct_matched
      result.should == 80.0
    end
  end

  describe ".status" do
  	it "returns the number of hearing statuses" do
  	 status = 'Status1'
     2.times do |i|
       FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case), :hearing_status => status)
     end
  	 FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case), :hearing_status => 'Status2')
  	 Hearing.status.count.should == 3
  	end
  end

  describe "#date" do
  	context "hearing date set" do
  	  it "should return date value" do
        dt = DateTime.now
  	  	hearing = FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case), :hearing_date => dt)
  	  	hearing.date.should == dt
	    end
  	end
  	context "no hearing date set" do
	    it "should return min date value" do
  	  	hearing = FactoryGirl.create(:hearing, :case => FactoryGirl.create(:case), :hearing_date => nil)
  	  	hearing.date.should == DateTime.new(0)
   	  end
    end
  end

end
