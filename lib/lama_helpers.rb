module LAMAHelpers
  def import_to_database(incidents, client=nil)
    l = client || LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})

    incidents.each do |incident|
      case_number = incident.Number
      kase = Case.find_or_initialize_by_case_number(case_number)

      incident_full = l.incident(case_number)

      #Go through all data points and pull out relevant things here
      #Inspections
      inspections = incident_full.Inspections
      if inspections
        inspections.each do |inspection|
          inspection = inspection[1].first
          if inspection.class == Hashie::Mash
            i = Inspection.create(:case_number => case_number, :inspection_date => inspection.InspectionDate, :notes => inspection.Comment)
            if inspection.Findings != nil && inspection.Findings.InspectionFinding != nil
              inspection.Findings.InspectionFinding.each do |finding|
                if finding.class == Hashie::Mash
                  i.inspection_findings.build(:finding => finding.Finding, :label => finding.Label)
                end
              end
            end
          end
        end
      end
      #Actions
      actions = []
      if incident_full.Actions && incident_full.Actions.CodeAction
        actions == incident_full.Actions.CodeAction
      end
      if actions
        actions.each do |action|
          if action.class == Hashie::Mash
            if action.Type =~ /Notice of Hearing/
              Notification.create(:case_number => case_number, :notified => action.DateComplete, :notification_type => action.Type)
            end
            
            if action.Type =~ /Administrative Hearing/
              unless action.Type =~ /Notice/
               Hearing.create(:case_number => case_number, :hearing_date => action.DateComplete, :hearing_type => action.Type)
              end
            end
          end
        end
      end      

      #Events
      events = []
      if incident_full.Events && incident_full.Events.IncidEvent
        events = incident_full.Events.IncidEvent
      end
      if events
        events.each do |event|
          if event.class == Hashie::Mash
            if event.Type =~ /Notice of Hearing/
              Notification.create(:case_number => case_number, :notified => event.DateEvent, :notification_type => event.Type)
            end

            if event.Type =~ /Administrative Hearing/
             Hearing.create(:case_number => case_number, :hearing_date => event.DateEvent, :hearing_status => event.Status, :hearing_type => event.Type)
            end
            
            if event.Type =~ /Input Hearing Results/
             if event.Items != nil and event.IncidEventItem != nil
               event.IncidEventItem.each do |item|
                 if item.class == Hashie::Mash
                   if item.Title =~ /Reset Hearing/ && item.IsComplete == "true"
                      Reset.create(:case_number => case_number, :reset_date => item.DateCompleted)
                   end
                 end
               end
             end
            end
            if event.Name =~ /Hearing - Guilty:/
              notes = event.Name.gsub('Hearing - Guilty:','').strip
              Judgement.create(:case_number => case_number, :status => 'Guilty', :notes => notes, :judgement_date => event.DateEvent)
            end
         end
        end
      end

      #Violations
      #TODO: add violations table and create front end for this 
      
      #Judgments - Closed
      if incident_full.Description =~ /Status: Closed/
          d = incident_full.Description
          d = d[d.index('Status Date:') .. -1].split(' ')
          d = d[2].split('/')
          d = DateTime.new(d[2].to_i,d[0].to_i,d[1].to_i)
          Judgement.create(:case_number => case_number, :status => 'Closed', :judgement_date => d)
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
