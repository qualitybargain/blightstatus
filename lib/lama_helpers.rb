module LAMAHelpers
  def import_to_database(incidents, client=nil)
    l = client || LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})

    incidents.each do |incident|
      puts incident.to_s#inspect
      case_number = incident.Number
      next unless case_number # need to find a better way to deal with this ... revisit post LAMA data cleanup
      
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
  
            if event.Type =~ /Complaint Received/ || event.Name =~ /Complaint Received/
             Complaint.create(:case_number => case_number, :date_received => event.DateEvent, :status => event.Status)
            end

            j_status = nil
            if event.Name =~ /Guilty/ || (event.Name =~ /Hearing/ && event.Status =~ /Guilty/)
              if event.Name =~ /Guilty/
                notes = event.Name.strip
              else
                notes = event.Status.strip
              end
              if notes =~ /Not Guilty/
                j_status = 'Not Guilty'
              else
                j_status = 'Guilty'
              end
            elsif event.Name =~ /Dismiss/ || (event.Name =~ /Hearing/ && (event.Status =~ /Dismiss/ || event.Status =~ /dismiss/))
              if event.Name =~ /Dismiss/
                notes = event.Name.strip
              else
                notes = event.Status.strip
              end
              j_status = 'Closed'
            elsif event.Name =~ /Compliance/ || (event.Name =~ /Hearing/ && event.Status =~ /Compliance/)
              if event.Name =~ /Compliance/
                notes = event.Name.strip
              else
                notes = event.Status.strip
              end
              j_status = 'Closed'
            elsif event.Name =~ /Closed New Owner/ || (event.Name =~ /Hearing/ && event.Status =~ /Closed/)
              if event.Name =~ /Closed/
                notes = event.Name.strip
              else
                notes = event.Status.strip
              end
              j_status = 'Closed'
            elsif event.Name =~ /Judgment rescinded/ || (event.Name =~ /Hearing/ && event.Status =~ /Judgment rescinded/)
              if event.Name =~ /rescinded/
                notes = event.Name.strip
              else
                notes = event.Status.strip
              end
              j_status = 'Judgment Rescinded'
            end
            if j_status
              Judgement.create(:case_number => case_number, :status => j_status, :notes => notes, :judgement_date => event.DateEvent)  
            end
          end
        end
      end

      #Violations
      #TODO: add violations table and create front end for this 
      #Judgments - Closed
      case_status = incident_full.Description
      if (case_status =~ /Status:/ && case_status =~ /Status Date:/)
        case_status = case_status[((case_status =~ /Status:/) + "Status:".length) ... case_status =~ /Status Date:/].strip

        j_status = nil
        c_status = nil
        
        if case_status =~ /Closed/ || case_status =~ /In Compliance/ || case_status =~ /Dismiss/ || case_status =~ /dismiss/
            j_status = 'Closed'
        elsif case_status =~ /Not Guilty/
            j_status = 'Not Guilty'
        elsif case_status =~ /Guilty/
            j_status = 'Guilty'
        elsif case_status =~ /Judgment rescinded/
            j_status = 'Judgment Rescinded' 
        elsif case_status =~ /Complaint Received/
            c_status = 'Received'
        end

        if j_status || c_status
          d = incident_full.Description
          d = d[d.index('Status Date:') .. -1].split(' ')
          d = d[2].split('/')
          d = DateTime.new(d[2].to_i,d[0].to_i,d[1].to_i)
          if j_status
            Judgement.create(:case_number => case_number, :status => j_status, :judgement_date => d, :notes => case_status)
          end
          if c_status
            Complaint.create(:case_number => case_number, :status => c_status, :date_received => d, :notes => case_status)
          end
        end
      end
      
      #Address if case isn't already associated
      if kase.address.nil?
        addresses = AddressHelpers.find_address(incident.Location)
        unless addresses.empty?
          kase.address = addresses.first
        end
      end

      kase.save unless kase.accela_steps.nil?
    end
  end

end
