require 'spec_helper'

describe Account do
  it { should have_many(:subscriptions) }
  it { should have_many(:addresses) }

  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:password) }

  describe "#send_digest" do
    it "sends an email if subscribed addresses have been updated" do
      @subscription = FactoryGirl.create(:subscription)
      kase = FactoryGirl.create(:case)
      @subscription.address.cases << kase
      FactoryGirl.create(:inspection, :case_number => kase.case_number)
      @subscription.account.send_digest
      Delayed::Job.count.should eq(1)
    end

    it "doesn't send an email if subscribed addresses have not been updated" do
      account = FactoryGirl.create(:account)
      account.send_digest
      Delayed::Job.count.should eq(0)
    end
  end
end
