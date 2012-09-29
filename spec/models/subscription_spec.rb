require 'spec_helper'

describe Subscription do
  it { should belong_to(:address) }
  it { should belong_to(:account) }

  describe "#updated_since_last_notification?" do
    before do
      @subscription = FactoryGirl.create(:subscription)
      kase = FactoryGirl.create(:case)
      @subscription.address.cases << kase
      FactoryGirl.create(:inspection, :case_number => kase.case_number)
    end

    it "returns true if an address or addresses' steps have been updated" do
      @subscription.updated_since_last_notification?.should be_true
    end

    it "returns false if an address has not been updated" do
      @subscription.date_notified = Time.now

      @subscription.updated_since_last_notification?.should be_false
    end
  end
end
