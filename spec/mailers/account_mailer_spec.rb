require "spec_helper"

describe AccountMailer do
  context "#deliver_digest" do
    before do
      @subs = [FactoryGirl.create(:subscription)]
      @account = @subs.first.account

      @email = AccountMailer.deliver_digest(@account, @subs).deliver
    end

    it "sends an email" do
      ActionMailer::Base.deliveries.empty?.should == false
    end

    it "goes to the address of the account" do
      @email.to.first.should == @account.email
    end

    it "comes from blightstatus" do
      @email.from.first.should == "blightstatus@nola.gov"
    end
  end
end
