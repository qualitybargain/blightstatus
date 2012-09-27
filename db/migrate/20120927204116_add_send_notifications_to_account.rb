class AddSendNotificationsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :send_notifications, :boolean

  end
end
