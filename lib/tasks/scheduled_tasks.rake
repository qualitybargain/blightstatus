namespace :scheduled_tasks do
  desc "Send out notifications"
  task :send_notifications => :environment do

    Subscription.send_notifications
    # send_notifications
  end

end


