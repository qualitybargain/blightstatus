require "#{Rails.root}/lib/lama_helpers.rb"
include LAMAHelpers

namespace :lama do
  desc "Import updates from LAMA"
  task :load_latest, [:start_date, :end_date] => :environment do |t, args|
    date = Time.now
    args.with_defaults(:start_date => date - 2.weeks, :end_date => date)

    l = LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})
    incidents = l.incidents_by_date(args.start_date, args.end_date)

    incid_num = incidents.length
    p "There are #{incid_num} incidents"
    if incid_num >= 1000
      p "LAMA can only return 1000 incidents at once- please try a smaller date range"
      return
    end

    LAMAHelpers.import_to_database(incidents, l)
  end

  desc "Import LAMA data from our Accela endpoint until current time"
  task :load_historical => :environment do |t, args|
    start_date = Time.now
    end_date = Date.new(2012, 3, 1)

    l = LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})
    
    while start_date > end_date
      call_end_date = start_date - 1.week
      incidents = l.incidents_by_date(call_end_date, start_date)
  
      if incidents
        p "There are #{incidents.length} incidents"
        LAMAHelpers.import_to_database(incidents, l)
      end
      start_date = call_end_date
    end
  end
end
