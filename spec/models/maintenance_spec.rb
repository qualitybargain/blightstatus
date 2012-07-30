require 'spec_helper'

describe Maintenance do

	before(:each) do
    	@maintenance = FactoryGirl.create(:maintenance, :address => FactoryGirl.create(:address))
 	end
	it { should belong_to(:address) }


	describe "#date" do
  	it "nil date should return DateTime.new(0)" do
  		maintenance = FactoryGirl.create(:maintenance, :date_recorded => nil, :date_completed => nil)
  		result = maintenance.date
  		result.should eq(DateTime.new(0))
  	end
  	
  	it "set date should return dt" do
  		dt = DateTime.now - 1.day
  		maintenance = FactoryGirl.create(:maintenance, :date_completed => dt)
  		result = maintenance.date
  		result.should eq(dt)
  	end
  end

  describe "#self.matched_count" do
    	it "should return the totl count of maintenances matched to cases" do
			FactoryGirl.create(:maintenance)
			result = Maintenance.matched_count
			result.should eq(1)
		end
	end

	describe "#self.unmatched_count" do
		it "should return the total count of maintenances that do not match cases" do
			FactoryGirl.create(:maintenance)
			result = Maintenance.unmatched_count
			result.should eq(1)
		end
	end

	describe "#self.pct_matched" do
		it "% of maintenances matched to a case" do
			FactoryGirl.create(:maintenance)
			FactoryGirl.create(:maintenance)
			FactoryGirl.create(:maintenance)
			result = Maintenance.pct_matched
			result.should eq(25)
		end
	end
	
	describe "#self.status" do
		it "return the # of distinct maintenance status in database" do
			FactoryGirl.create(:maintenance, :status => 'guilty')
			FactoryGirl.create(:maintenance, :status => 'closed')
			FactoryGirl.create(:maintenance, :status => 'dismissed')
			result = Maintenance.status.count
			result.should eq(4)
		end
	end


	describe "#self.program_names" do
		it "return the # of distict program_names in database" do
			FactoryGirl.create(:maintenance, :program_name => 'Prog1')
			FactoryGirl.create(:maintenance, :program_name => 'Prog2')
			FactoryGirl.create(:maintenance, :program_name => 'Prog3')
			result = Maintenance.program_names.count
			result.should eq(4)
		end
	end
end
