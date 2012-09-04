class SubscriptionMailer < ActionMailer::Base
  default from: "status@blightstatus.com"



  def subscription_email(account, addresses)
    @account = account
    @addresses = addresses
    mail(:to => account.email, :subject => "BlightStatus Notification Subject")
  end

end
