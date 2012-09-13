class AccountMailer < ActionMailer::Base
  default from: "blightstatus@codeforamerica.org"

  def deliver_digest(account, subs)
    @account = account
    @subs = subs
    mail(:to => @account.email, :subject => "Blightstatus notifications for #{Time.now.to_date}")
  end
end
