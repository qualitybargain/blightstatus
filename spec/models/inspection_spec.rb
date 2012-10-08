require 'spec_helper'

describe Inspection do
  before(:each) do
    @inspection = FactoryGirl.create(:inspection)
  end

	it { should belong_to(:inspector) }
	it { should belong_to(:case) }

  describe "case number and date validations" do
  	it "should not create multiple hearings for the same date with the same case" do
	    time = Time.now
	    c = FactoryGirl.create(:case)
	    FactoryGirl.create(:inspection, :case_number => c.case_number, :inspection_date => time)

	    lambda { FactoryGirl.create(:inspection, :case_number => c.case_number, :inspection_date => time) }.should raise_error(ActiveRecord::RecordInvalid, /already been taken/)
    end
  end

  describe "#date" do
    let(:dt){ DateTime.now - 2.days }

  	it "nil date should return DateTime.new(0)" do
  		inspection = FactoryGirl.create(:inspection, :inspection_date => nil, :scheduled_date => nil)
  		result = inspection.date
  		result.should eq(DateTime.new(0))
  	end

    context "inspection date set" do
      it "returns the inspection date" do
        inspection = FactoryGirl.create(:inspection, :inspection_date => dt, :scheduled_date => nil)
        inspection.date.should eq(dt)
      end
    end
    
    context "scheduled date set" do
      it "returns the scheduled date" do
        inspection = FactoryGirl.create(:inspection, :inspection_date => nil, :scheduled_date => dt)
        inspection.date.should eq(dt)
      end
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

  describe ".matched_count" do
    	it "should return the total count of inspections matched to cases" do
			FactoryGirl.create(:inspection, :case => FactoryGirl.create(:case))
			result = Inspection.matched_count
			result.should eq(1)
		end
	end

	describe ".unmatched_count" do
		it "should return the total count of inspections that do not match cases" do
			FactoryGirl.create(:inspection, :case => FactoryGirl.create(:case))
			result = Inspection.unmatched_count
			result.should eq(1)
		end
	end

	describe ".pct_matched" do
		it "% of inspections matched to a case" do
      c = FactoryGirl.create(:case)
      3.times do |i|
        FactoryGirl.create(:inspection, :case => c)
      end
			result = Inspection.pct_matched
			result.should eq(75)
		end
	end
	
	describe ".types" do
		it "return the # of distict inspection status in database" do
			FactoryGirl.create(:inspection, :inspection_type => 'guilty')
			FactoryGirl.create(:inspection, :inspection_type => 'closed')
			FactoryGirl.create(:inspection, :inspection_type => 'dismissed')
			result = Inspection.types.count
			result.should eq(4)
		end
	end

	describe ".results" do
		it "return the # of distict results status in database" do
      %w('guilty', 'closed', 'dismissed').each do |status|
        FactoryGirl.create(:inspection, :inspection_date => DateTime.new(rand(100)), :result => status)
      end
			result = Inspection.results.count
			result.should eq(4)
		end
	end
end
