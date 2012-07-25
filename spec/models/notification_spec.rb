require 'spec_helper'

describe Notification do

	before(:each) do
    	@notification = FactoryGirl.create(:notification, :case => FactoryGirl.create(:case))
  	end

  it { should belong_to(:case) }

  it "should not create multiple notifications of the same type for the same case with the same date" do
    time = Time.now
    c = FactoryGirl.build(:case)
    FactoryGirl.create(:notification,:case_number => c.case_number, :notified => time, :notification_type => "Posting of Notice")
    lambda { FactoryGirl.create(:notification, :case_number => c.case_number, :notified => time, :notification_type => "Posting of Notice") }.should raise_error(ActiveRecord::RecordInvalid, /already been taken/)
    Notification.count.should eq 2
  end

  describe "#date" do
  	it "nil date should return DateTime.new(0)" do
  		notification = FactoryGirl.create(:notification, :notified => nil)
  		result = notification.date
  		result.should eq(DateTime.new(0))
  	end
  	it "set date should return dt" do
  		dt = DateTime.now - 2.days
  		notification = FactoryGirl.create(:notification, :notified => dt)
  		result = notification.date
  		result.should eq(dt)
  	end
  end


  describe "#self.matched_count" do
    	it "should return the totl count of notifications matched to cases" do
			FactoryGirl.create(:notification)
			result = Notification.matched_count
			result.should eq(1)
		end
	end

	describe "#self.unmatched_count" do
		it "should return the total count of notifications that do not match cases" do
			FactoryGirl.create(:notification)
			result = Notification.unmatched_count
			result.should eq(1)
		end
	end

	describe "#self.pct_matched" do
		it "% of notifications matched to a case" do
			FactoryGirl.create(:notification, :notification_type => 'guilty')
			FactoryGirl.create(:notification, :notification_type => 'closed')
			FactoryGirl.create(:notification, :notification_type => 'dismissed')
			result = Notification.pct_matched
			result.should eq(25)
		end
	end
	
	describe "#self.types" do
		it "return the # of distict notification status in database" do
			FactoryGirl.create(:notification, :notification_type => 'guilty')
			FactoryGirl.create(:notification, :notification_type => 'closed')
			FactoryGirl.create(:notification, :notification_type => 'dismissed')
			result = Notification.types.count
			result.should eq(4)
		end
	end
end
