class SubscriptionMailer < ActionMailer::Base
  default :from => "notifications@blightstatus.org"
 
  def notify(user, properties)
    @user = user
    mail(:to => user.email, :subject => "Welcome to My Awesome Site")
  end

end

