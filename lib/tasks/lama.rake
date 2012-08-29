namespace :lama do
  desc "Import updates from LAMA"
  task :load_latest, [:start_date, :end_date] => :environment do |t, args|

    #TODO: Make this work

    date = Time.now
    args.with_defaults(:start_date => date - 2.weeks, :end_date => date)
    l = LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})
    incidents = l.incidents_by_date(args.start_date, args.end_date)

    p "There are #{incidents.length} incidents"
    incidents.first(5).each do |incident|
      case_number = incident.Number
      kase = Case.find_or_initialize_by_case_number(case_number)

      incident_full = l.incident(case_number)

      #Go through all data points and pull out relevant things here
      #Inspections
      inspections = incident_full.Inspections
      inspections.each do |inspection|
        inspection = inspection[1].first
        if inspection.class == "Hashie::Mash"
          Inspection.create(:case_number => case_number, :inspection_date => inspection.InspectionDate, :notes => inspection.Comment, :result => inspection.Findings)
        end
      end
      
      #Actions
      actions = []
      if incident_full.Actions && incident_full.Actions.CodeAction
        actions == incident_full.Actions.CodeAction
      end
      actions.each do |action|
        if action.Type =~ /Notice/
          Notification.create(:case_number => case_number, :notified => action.DateComplete, :notification_type => action.Type)
        end
        
        if action.Type =~ /Hearing/
          unless action.Type =~ /Notice/
           Hearing.create(:case_number => case_number, :hearing_date => action.DateComplete, :hearing_type => action.Type)
          end
        end
      end
      
      events = []
      if incident_full.Events && incident_full.Events.IncidEvent
        events = incident_full.Events.IncidEvent
      end
      events.each do |event|
        if event.class == "Hashie::Mash"
           if event.Type =~ /Notice/
            Notification.create(:case_number => case_number, :notified => event.DateEvent, :notification_type => event.Type)
           end
           
           if event.Type =~ /Hearing/
             unless event.Type =~ /Notice/
             Hearing.create(:case_number => case_number, :hearing_date => event.DateEvent, :hearing_status => event.Status, :hearing_type => event.Type)
           end
          end
       end
     end

      #Violations
      #TODO: add violations table and create front end for this 
      
      #Judgments
      judgements = incident_full.Judgements
      if judgements
        pp judgements
      end

      #Address if case isn't already associated
      if kase.address.nil?
        addresses = AddressHelpers.find_address(incident.Location)
        unless addresses.empty?
          kase.address = addresses.first
          kase.save
        end
      end

    end
  end
end
