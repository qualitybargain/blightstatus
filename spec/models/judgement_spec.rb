require 'spec_helper'

describe Judgement do
  before(:each) do
    @judgement = FactoryGirl.create(:judgement, :case => FactoryGirl.create(:case))
  end
  
  it { should belong_to(:case) }

    describe "#self.matched_count" do
    	it "should return the totl count of judgements matched to cases" do
			FactoryGirl.create(:judgement)
			result = Judgement.matched_count
			result.should eq(1)
		end
	end

	describe "#self.unmatched_count" do
		it "should return the total count of judgements that do not match cases" do
			FactoryGirl.create(:judgement)
			result = Judgement.unmatched_count
			result.should eq(1)
		end
	end

	describe "#self.pct_matched" do
		it "% of judgements matched to a case" do
			FactoryGirl.create(:judgement)
			FactoryGirl.create(:judgement)
			FactoryGirl.create(:judgement)
			result = Judgement.pct_matched
			result.should eq(25)
		end
	end
	
	describe "#self.status" do
		it "return the # of distict judgement status in database" do
			FactoryGirl.create(:judgement, :status => 'guilty')
			FactoryGirl.create(:judgement, :status => 'closed')
			FactoryGirl.create(:judgement, :status => 'dismissed')
			result = Judgement.status.count
			result.should eq(3)
		end
	end
end
