module LAMAHelpers
  def import_to_database(incidents, client=nil)
    l = client || LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})

    incidents.each do |incident|
      case_number = incident.Number
      next unless case_number # need to find a better way to deal with this ... revisit post LAMA data cleanup
      
      kase = Case.find_or_create_by_case_number(:case_number => case_number, :state => 'Open')
      puts "case => #{case_number}   status => #{incident.CurrentStatus}"
      orig_state = kase.state
      incident_full = l.incident(case_number)
      
      #Go through all data points and pull out relevant things here
      #Inspections
      inspections = incident_full.Inspections
      if inspections
        if inspections.class == Hashie::Mash
          inspections = inspections.Inspection
          if inspections.class == Array
            inspections.each do |inspection|
              parseInspection(case_number,inspection)          
            end
          else
            parseInspection(case_number,inspections)
          end
        end
      end
      #Actions
      actions = []
      if incident_full.Actions && incident_full.Actions.CodeAction
        actions = incident_full.Actions.CodeAction
        if actions
          if actions.class == Array
            actions.each do |action|
              parseAction(kase, action)          
            end
          else
            parseAction(kase, actions)
          end     
        end      
      end
      #Events
      events = []
      if incident_full.Events && incident_full.Events.IncidEvent
        events = incident_full.Events.IncidEvent
      end
      if events
        if events.class == Array
          events.each do |event|
            parseEvent(kase,event)          
          end
        else
          parseEvent(kase,events)
        end
      end

      #Violations
      #TODO: add violations table and create front end for this 
      #Judgments - Closed
      case_status = incident_full.Description
      if (case_status =~ /Status:/ && case_status =~ /Status Date:/)
        case_status = case_status[((case_status =~ /Status:/) + "Status:".length) ... case_status =~ /Status Date:/].strip

        d = incident_full.Description
        d = d[d.index('Status Date:') .. -1].split(' ')
        d = d[2].split('/')
        d = DateTime.new(d[2].to_i,d[0].to_i,d[1].to_i)

        parseStatus(kase,case_status,d)
      end
      
      if incident.CurrentStatus
        #if kase.state == orig_state
          case_status = incident.CurrentStatus
          d = incident.CurrentStatusDate
          
          parseStatus(kase,case_status,d)
        #end
      end
      
      #Address if case isn't already associated
      if kase.address.nil?
        addresses = AddressHelpers.find_address(incident.Location)
        unless addresses.empty?
          kase.address = addresses.first
        end
      end
      if !kase.accela_steps.nil? || kase.state != orig_state
        k = kase.save
      end
    end
  end

  def parseEvent(kase,event)
    case_number = kase.case_number
    if event.class == Hashie::Mash #&& event.IsComplete =~ /true/
      j_status = nil
      if event.Type =~ /Notice/ && event.Type =~ /Hearing/
        Notification.create(:case_number => kase.case_number, :notified => event.DateEvent, :notification_type => event.Type)
      elsif event.Type =~ /Administrative Hearing/
       Hearing.create(:case_number => kase.case_number, :hearing_date => event.DateEvent, :hearing_status => event.Status, :hearing_type => event.Type)
      elsif event.Type =~ /Input Hearing Results/
       if event.Items != nil and event.IncidEventItem != nil
         event.IncidEventItem.each do |item|
           if item.class == Hashie::Mash
             if (item.Title =~ /Reset Notice/ || item.Title =~ /Reset Hearing/) && item.IsComplete == "true"
                Reset.create(:case_number => kase.case_number, :reset_date => item.DateCompleted)
             end
           end
         end
       end
      elsif event.Type =~ /Inspection/ || event.Name =~ /Inspection/ || event.Type =~ /Reinspection/ || event.Name =~ /Reinspection/
        i = Inspection.create(:case_number => kase.case_number, :inspection_date => event.DateEvent, :notes => event.Status, :inspection_type => event.Type)
      elsif event.Type =~ /Complaint Received/ || event.Name =~ /Complaint Received/
       Complaint.create(:case_number => kase.case_number, :date_received => event.DateEvent, :status => event.Status)
      elsif event.Name =~ /Guilty/ || (event.Name =~ /Hearing/ && event.Status =~ /Guilty/)
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
        kase.state = j_status
      elsif (event.Name =~ /Judgment/ && (event.Name =~ /Posting/ || event.Name =~ /Notice/ || event.Name =~ /Recordation/))
        j_status = ''
        kase.state = 'Judgment'
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Dismiss/) || (event.Name =~ /Hearing/ && (event.Status =~ /Dismiss/ || event.Status =~ /dismiss/))
        if event.Name =~ /Dismiss/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Closed'
        kase.state = 'Closed: Dismissed'
      elsif event.Name =~ /Dismiss/
        kase.state = 'Dismissed'
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Compliance/) || (event.Name =~ /Hearing/ && event.Status =~ /Compliance/)
        if event.Name =~ /Compliance/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Closed'
        kase.state = 'Closed: In Compliance'
      elsif event.Name =~ /Compliance/
        kase.state = "Closed: In Compliance"
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Closed/) || (event.Name =~ /Hearing/ && event.Status =~ /Closed/)
        if event.Name =~ /Closed/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Closed'
        kase.state = 'Closed'
      elsif event.Name =~ /Closed New Owner/
        kase.state = 'Closed: New Owner'
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Judgment rescinded/) || (event.Name =~ /Hearing/ && event.Status =~ /Judgment rescinded/)
        if event.Name =~ /rescinded/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Judgment Rescinded'
        kase.state = j_status
      elsif event.Name =~ /Closed/# || event.Name == 'Closed - Closed'
        kase.state = "Closed"
      elsif event.Name =~ /Judgment rescinded/
        kase.state = 'Judgment Rescinded'
      end
      
      if j_status
        Hearing.create(:case_number => kase.case_number, :hearing_date => event.DateEvent, :hearing_status => j_status)
        Judgement.create(:case_number => kase.case_number, :status => j_status, :notes => notes, :judgement_date => event.DateEvent)             
      end
    end
  end
  def parseInspection(case_number,inspection)
    if inspection.class == Hashie::Mash
      i = Inspection.find_or_create_by_case_number_and_inspection_date(:case_number => case_number, :inspection_date => inspection.InspectionDate, :notes => inspection.Comment)
      if inspection.Findings != nil && inspection.Findings.InspectionFinding != nil
        inspection.Findings.InspectionFinding.each do |finding|
          if finding.class == Hashie::Mash
            if finding.Finding && finding.Finding.length > 0
              i.inspection_findings.create(:finding => finding.Finding, :label => finding.Label)
            end
          end
        end
      end
    end
  end
  def parseAction(kase,action)
    if action.class == Hashie::Mash #&& action.IsComplete =~ /true/
      if action.Type =~ /Notice/ && action.Type =~ /Hearing/
        Notification.create(:case_number => kase.case_number, :notified => action.Date, :notification_type => action.Type)
      elsif action.Type =~ /Notice/ && action.Type =~ /Reset/
        Reset.create(:case_number => kase.case_number, :reset_date => action.Date)
      elsif action.Type =~ /Notice/ && action.Type =~ /Compliance/
        kase.state = 'Closed: In Compliance'
      elsif action.Type =~ /Judgment/ && (action.Type =~ /Posting/ || action.Type =~ /Recordation/ || action.Type =~ /Notice/)
        Judgement.create(:case_number => kase.case_number, :status => '', :judgement_date => action.Date, :notes => action.Type)
        kase.state = 'Judgment'
      elsif action.Type =~ /Administrative Hearing/
        unless action.Type =~ /Notice/
         Hearing.create(:case_number => kase.case_number, :hearing_date => action.Date, :hearing_type => action.Type)
        end
      end
    end
  end
  def parseStatus(kase,case_status,date)
    if case_status =~ /Compliance/ 
      kase.state = "Closed: In Compliance"
    elsif case_status =~ /Dismiss/ || case_status =~ /dismiss/
      kase.state = 'Closed: Dismissed'
    elsif case_status =~ /Closed/ 
      kase.state = 'Closed'
    elsif case_status =~ /Not Guilty/
      kase.state = 'Not Guilty'
      Judgement.create(:case_number => kase.case_number, :status => 'Not Guilty', :judgement_date => date, :notes => case_status)
    elsif case_status =~ /Guilty/
      kase.state = 'Guilty'
      Judgement.create(:case_number => kase.case_number, :status => 'Guilty', :judgement_date => date, :notes => case_status)
    elsif case_status =~ /Judgment/ && (case_status =~ /Posting/ || case_status =~ /Notice/ || case_status =~ /Recordation/)
      kase.state = 'Judgment'
      Judgement.create(:case_number => kase.case_number, :status => '', :judgement_date => date, :notes => case_status)
    elsif case_status =~ /Judgment rescinded/
      kase.state = 'Judgment Rescinded' 
    elsif case_status =~ /omplaint/ && case_status =~ /eceived/
      Complaint.create(:case_number => kase.case_number, :status => 'Received', :date_received => date, :notes => case_status)
    end
  end
end
