require 'spec_helper'

describe Inspection do
	before(:each) do
    	@inspection = FactoryGirl.create(:inspection, :case => FactoryGirl.create(:case), :inspector => FactoryGirl.create(:inspector))
  	end
	it { should belong_to(:inspector) }
	it { should belong_to(:case) }

  describe "tesst uniqe date per case" do
  	it "should not create multiple hearings for the same date with the same case" do
	    time = Time.now
	    c = FactoryGirl.create(:case)

	    FactoryGirl.create(:inspection, :case_number => c.case_number, :inspection_date => time)
	    #FactoryGirl.create(:inspection, :case_number => c.case_number, :inspection_date => time)
	    
	    lambda { FactoryGirl.create(:inspection, :case_number => c.case_number, :inspection_date => time) }.should raise_error(ActiveRecord::RecordInvalid, /already been taken/)


	    #Inspection.count.should eq 1
	end
  end

  describe "#date" do
  	it "nil date should return DateTime.new(0)" do
  		inspection = FactoryGirl.create(:inspection, :inspection_date => nil, :scheduled_date => nil)
  		result = inspection.date
  		result.should eq(DateTime.new(0))
  	end
  	it "set date should return dt" do
  		dt = DateTime.now - 2.days
  		inspection = FactoryGirl.create(:inspection, :inspection_date => dt, :scheduled_date => nil)
  		result = inspection.date
  		result.should eq(dt)
  	end
  	it "set date should return dt" do
  		dt = DateTime.now - 3.days
  		inspection = FactoryGirl.create(:inspection, :inspection_date => nil, :scheduled_date => dt)
  		result = inspection.date
  		result.should eq(dt)
  	end
  end


  describe "#self.matched_count" do
    	it "should return the totl count of inspections matched to cases" do
			FactoryGirl.create(:inspection)
			result = Inspection.matched_count
			result.should eq(1)
		end
	end

	describe "#self.unmatched_count" do
		it "should return the total count of inspections that do not match cases" do
			FactoryGirl.create(:inspection)
			result = Inspection.unmatched_count
			result.should eq(1)
		end
	end

	describe "#self.pct_matched" do
		it "% of inspections matched to a case" do
			FactoryGirl.create(:inspection)
			FactoryGirl.create(:inspection)
			FactoryGirl.create(:inspection)
			result = Inspection.pct_matched
			result.should eq(25)
		end
	end
	
	describe "#self.types" do
		it "return the # of distict inspection status in database" do
			FactoryGirl.create(:inspection, :inspection_type => 'guilty')
			FactoryGirl.create(:inspection, :inspection_type => 'closed')
			FactoryGirl.create(:inspection, :inspection_type => 'dismissed')
			result = Inspection.types.count
			result.should eq(4)
		end
	end

	describe "#notes" do
		it "should return notes" do
			txt = 'inspected by In Spector on #{DateTime.now}'
			@inspection.result = txt
			result = @inspection.notes
			result.should eq(txt)
		end
	end
	describe "#self.results" do
		it "return the # of distict results status in database" do
			FactoryGirl.create(:inspection, :result => 'guilty')
			FactoryGirl.create(:inspection, :result => 'closed')
			FactoryGirl.create(:inspection, :result => 'dismissed')
			result = Inspection.results.count
			result.should eq(4)
		end
	end
end
