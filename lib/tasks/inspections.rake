namespace :lama do
  desc "Import updates from LAMA"
  task :load_latest, [:start_date, :end_date] => :environment do |t, args|

    #TODO: Make this work

    args.with_defaults(:start_date => Time.now - 2.weeks, :end_date => Time.now)
    l = LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})
    incidents = l.incidents_by_date(args.start_date, args.end_date)

    incidents.each do |incident|
      case_number = incident.Number
      kase = Case.find_or_initialize_by_case_number(case_number)

      incident_full = l.incident(case_number)
      #Go through all data points and pull out relevant things here

    end
  end
end
