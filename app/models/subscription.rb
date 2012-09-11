class Subscription < ActiveRecord::Base
  belongs_to :account
  belongs_to :address

  def self.send_notifications
    accounts = Account.find(:all)

	# TODO: need to make sure not to send duplicates
    accounts.each{ | account | 

      subscriptions = Subscription.find_all_by_account_id(account)
      SubscriptionMailer.subscription_email(account, subscriptions).deliver

      subscriptions.each{ | subscription |
      	subscription.date_notified = Time.now
      	subscription.save!
      }
    }
  end

end
