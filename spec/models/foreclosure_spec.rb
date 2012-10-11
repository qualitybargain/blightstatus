require 'spec_helper'

describe Foreclosure do
  before(:each) do
    @foreclosure = FactoryGirl.create(:foreclosure, :case => FactoryGirl.create(:case), :address => FactoryGirl.create(:address))
  end
  
  it { should belong_to(:case) }
  it { should belong_to(:address) }

  describe "#date" do
  	it "nil date should return DateTime.new(0)" do
  		foreclosure = FactoryGirl.create(:foreclosure, :sale_date => nil)
  		result = foreclosure.date
  		result.should eq(DateTime.new(0))
  	end
  	it "set date should return dt" do
  		dt = DateTime.now
  		foreclosure = FactoryGirl.create(:foreclosure, :sale_date => dt)
  		result = foreclosure.date
  		result.should eq(dt)
  	end
  end

  describe "#self.matched_count" do
    	it "should return the totl count of foreclosures matched to cases" do
			FactoryGirl.create(:foreclosure)
			result = Foreclosure.matched_count
			result.should eq(1)
		end
	end

	describe "#self.unmatched_count" do
		it "should return the total count of foreclosures that do not match cases" do
			FactoryGirl.create(:foreclosure)
			result = Foreclosure.unmatched_count
			result.should eq(1)
		end
	end

	describe "#self.pct_matched" do
		it "% of foreclosures matched to a case" do
      3.times do 
        FactoryGirl.create(:foreclosure, :sale_date => Time.now - Random.rand(3).days)
      end
			result = Foreclosure.pct_matched
			result.should eq(25)
		end
	end
	
	describe "#self.status" do
		it "return the # of distict foreclosure status in database" do
      %w('guilty', 'closed', 'dismissed').each do |stat|
        FactoryGirl.create(:foreclosure, :status => stat, :sale_date => Time.now - Random.rand(3).days)
      end
			result = Foreclosure.status.count
			result.should eq(4)
		end
	end
end
