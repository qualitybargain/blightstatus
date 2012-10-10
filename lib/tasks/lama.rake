require 'open-uri'
require 'json'
require "#{Rails.root}/lib/lama_helpers.rb"
include LAMAHelpers

namespace :lama do
  desc "Import updates from LAMA"
  task :load_by_date, [:start_date, :end_date] => :environment do |t, args|
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

  desc "Import day's LAMA events"
  task :load_latest => :environment do |t, args|
    date = Time.now
    end_date = date - 1.day

    Rake::Task["lama:load_by_date"].invoke(end_date, date)

    Hearing.clear_incomplete
    Account.all.each(&:send_digest)
  end

  desc "Import LAMA data from our Accela endpoint until current time"
  task :load_historical => :environment do |t, args|
    start_date = Time.now #Date.new(2012, 5, 30)#Time.now
    end_date = Date.new(2012, 1, 1)

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

  desc "Import updates from LAMA by parameter pipe (|) delimited string of cases"
  task :load_by_case, [:case_numbers] => :environment do |t, args|
    l = LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})
    incidents = []
    case_numbers = args[:case_numbers].split('|')

    case_numbers.each do |case_number|
      case_number = case_number.strip
      incidents << l.incident(case_number)
    end

    incid_num = incidents.length
    p "There are #{incid_num} incidents"
    if incid_num >= 1000
      p "LAMA can only return 1000 incidents at once- please try a smaller date range"
      return
    end

    LAMAHelpers.import_to_database(incidents, l)
  end


  desc "Compare cases in our system to cases from Accela spreadsheets"
  task :compare_to_accela, [:filename] => :environment do |t, args|
    args.with_defaults(:filename => "#{Rails.root}/tmp/db_accela_compare_#{DateTime.now.strftime("%Y%m%d%H%M%s")}.csv")
    puts "fileneme => #{args[:filename]}"

    File.open(args[:filename], "w+") do |f|
      page = 1
      url = "https://blightstatus-dev.herokuapp.com/cases.json?page=#{page}"
      result = JSON.parse(open(url).read)
      while result.count > 0
        result.each do |c|
          unless Case.exists?(:case_number => c["case_number"])
            puts c["case_number"]
            f.write(c["case_number"] << "\r")
          end
        end
        page += 1
        url = "https://blightstatus-dev.herokuapp.com/cases.json?page=#{page}"
        result = JSON.parse(open(url).read)
      end
    end
  end
end
