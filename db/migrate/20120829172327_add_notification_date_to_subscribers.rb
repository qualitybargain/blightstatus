class AddNotificationDateToSubscribers < ActiveRecord::Migration
  def change
  	add_column :subscriptions, :date_notified, :datetime
  end
end
