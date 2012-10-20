class AccountMailer < ActionMailer::Base
  default from: "blightstatus@nola.gov"

  def deliver_digest(account, subs)
    @account = account
    @subs = subs
    mail(:to => @account.email, :subject => "Blightstatus notifications for #{Time.now.to_date}")
  end
end
