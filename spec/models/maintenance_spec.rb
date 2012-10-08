require 'spec_helper'

describe Maintenance do

	before(:each) do
    	@maintenance = FactoryGirl.create(:maintenance, :address => FactoryGirl.create(:address))
 	end
	it { should belong_to(:address) }


	describe "#date" do
    context "no date recorded or date completed" do
      it "it returns a new DateTime object" do
        maintenance = FactoryGirl.create(:maintenance, :date_recorded => nil, :date_completed => nil)
        maintenance.date.should == DateTime.new(0)
      end
    end
  	
    context "date completed" do
      it "returns the date completed" do
        dt = Time.now
        maintenance = FactoryGirl.create(:maintenance, :date_completed => dt)
        maintenance.date.should == dt
      end
    end

    context "date recorded" do
      it "returns the date recorded" do
        dt = Time.now
        maintenance = FactoryGirl.create(:maintenance, :date_recorded => dt)
        maintenance.date.should == dt
      end
    end
  end

  describe ".matched_count" do
    it "returns the totl count of maintenances matched to cases" do
			FactoryGirl.create(:maintenance)
			result = Maintenance.matched_count
			result.should eq(1)
		end
	end

	describe ".unmatched_count" do
		it "should return the total count of maintenances that do not match cases" do
			FactoryGirl.create(:maintenance)
			result = Maintenance.unmatched_count
			result.should eq(1)
		end
	end

	describe ".pct_matched" do
		it "% of maintenances matched to a case" do
      3.times do |i|
        FactoryGirl.create(:maintenance)
      end
			result = Maintenance.pct_matched
			result.should eq(25)
		end
	end
	
	describe ".status" do
		it "return the # of distinct maintenance status in database" do
      %w('guilty', 'closed', 'dismissed').each do |w|
        FactoryGirl.create(:maintenance, :status => w)
      end
			result = Maintenance.status.count
			result.should eq(4)
		end
	end


	describe ".program_names" do
		it "return the # of distict program_names in database" do
      3.times do |i|
        FactoryGirl.create(:maintenance, :program_name => 'Prog' + i.to_s)
      end
			result = Maintenance.program_names.count
			result.should eq(4)
		end
	end
end
