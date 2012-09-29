class Subscription < ActiveRecord::Base
  belongs_to :account
  belongs_to :address

  def updated_since_last_notification?
    last_notified = date_notified || Date.new(1970, 2, 3)
    address.workflow_steps.any?{ |step| step.updated_at > last_notified }
  end
end
