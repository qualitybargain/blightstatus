task :send_daily_mail => :environment do
    Model.send_daily_mail
end

