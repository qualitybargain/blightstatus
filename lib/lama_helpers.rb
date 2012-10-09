module LAMAHelpers
  def import_to_database(incidents, client=nil)
    l = client || LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})

    incidents.each do |incident|
      case_number = incident.Number
      next unless case_number # need to find a better way to deal with this ... revisit post LAMA data cleanup
      
      division = get_incident_division_by_location(l,incident.Location,case_number)

      next unless division == 'CE'
      
      kase = Case.find_or_create_by_case_number(:case_number => case_number, :state => 'Open')
      kase.state = 'Closed' if incident.IsClosed =~/true/
      puts "case => #{case_number}   status => #{incident.CurrentStatus}"
      orig_state = kase.state
      orig_outcome = kase.outcome
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
      
      if kase.address.nil?
        addresses = AddressHelpers.find_address(incident.Location)
        unless addresses.empty?
          kase.address = addresses.first
        end
      end
      if !kase.accela_steps.nil? || kase.state != orig_state || kase.outcome != orig_outcome
        k = kase.save
        #invalidate_steps(kase)
      end
    end
  end

  def parseEvent(kase,event)
    case_number = kase.case_number
    if event.class == Hashie::Mash && event.IsComplete =~ /true/
      j_status = nil
      if ((event.Type =~ /Notice/ || event.Name =~ /Notice/) && (event.Type =~ /Hearing/ || event.Name =~ /Hearing/)) || (event.Type == 'Notice' || event.Name == 'Notice')
        Notification.create(:case_number => kase.case_number, :notified => event.DateEvent, :notification_type => event.Type)#, :is_valid => true)
      elsif event.Type =~ /Administrative Hearing/
       Hearing.create(:case_number => kase.case_number, :hearing_date => event.DateEvent, :hearing_status => event.Status, :hearing_type => event.Type)#, :is_valid => true)
      elsif event.Type =~ /Input Hearing Results/
       if event.Items != nil and event.IncidEventItem != nil
         event.IncidEventItem.each do |item|
           if item.class == Hashie::Mash
             if (item.Title =~ /Reset Notice/ || item.Title =~ /Reset Hearing/) && item.IsComplete == "true"
                Reset.create(:case_number => kase.case_number, :reset_date => item.DateCompleted)#, :is_valid => true)
             end
           end
         end
       end
      elsif event.Type =~ /Inspection/ || event.Name =~ /Inspection/ || event.Type =~ /Reinspection/ || event.Name =~ /Reinspection/
        i = Inspection.create(:case_number => kase.case_number, :inspection_date => event.DateEvent, :notes => event.Status, :inspection_type => event.Type)#, :is_valid => true)
      elsif event.Type =~ /Complaint Received/ || event.Name =~ /Complaint Received/
       Complaint.create(:case_number => kase.case_number, :date_received => event.DateEvent, :status => event.Status)#, :is_valid => true)
      elsif (event.Name =~ /Guilty/ || event.Status =~ /Guilty/ || event.Type =~ /Guilty/) && (event.Name =~ /Hearing/ || event.Status =~ /Hearing/ || event.Type =~ /Hearing/)#event.Name =~ /Hearing/
        if event.Name =~ /Guilty/
          notes = event.Name.strip
        elsif event.Type =~ /Guilty/
          notes = event.Type.strip
        else
          notes = event.Status.strip
        end
        
        if notes =~ /Not Guilty/
          j_status = 'Not Guilty'
        else
          j_status = 'Guilty'
        end
        kase.outcome = j_status
      elsif (event.Name =~ /Judgment/ && (event.Name =~ /Posting/ || event.Name =~ /Notice/ || event.Name =~ /Recordation/))
        j_status = ''
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Dismiss/) || (event.Name =~ /Hearing/ && (event.Status =~ /Dismiss/ || event.Status =~ /dismiss/))
        if event.Name =~ /Dismiss/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Closed'
        kase.outcome = 'Closed: Dismissed'
      elsif event.Name =~ /Dismiss/
        kase.outcome = 'Dismissed'
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Compliance/) || (event.Name =~ /Hearing/ && event.Status =~ /Compliance/)
        if event.Name =~ /Compliance/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Closed'
        kase.outcome = 'Closed: In Compliance'
      elsif event.Name =~ /Compliance/
        kase.outcome = "Closed: In Compliance"
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Closed/) || (event.Name =~ /Hearing/ && event.Status =~ /Closed/)
        if event.Name =~ /Closed/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Closed'
        kase.outcome = 'Closed'
      elsif event.Name =~ /Closed New Owner/
        kase.outcome = 'Closed: New Owner'
      elsif (event.Name =~ /Hearing/ && event.Name =~ /Judgment rescinded/) || (event.Name =~ /Hearing/ && event.Status =~ /Judgment rescinded/)
        if event.Name =~ /rescinded/
          notes = event.Name.strip
        else
          notes = event.Status.strip
        end
        j_status = 'Judgment Rescinded'
        kase.outcome = j_status
      elsif event.Name =~ /Closed/# || event.Name == 'Closed - Closed'
        kase.outcome = "Closed"
      elsif event.Name =~ /Judgment rescinded/
        kase.outcome = 'Judgment Rescinded'
      end
      
      if j_status
        if j_status.length > 0
          Hearing.create(:case_number => kase.case_number, :hearing_date => event.DateEvent, :hearing_status => j_status)#, :is_valid => true)

          # j = kase.judgement
          Judgement.create(:case_number => kase.case_number, :notes => notes, :status => j_status, :judgement_date => event.DateEvent)#, :is_valid => true)
          # k = Judgement.new(:case_number => kase.case_number, :notes => notes, :status => j_status, :judgement_date => event.DateEvent)#, :is_valid => true)
          
          # if j && j.status.nil?
          #   invalidate_steps(kase, j)
          #   #Judgement.delete_all("case_number = '#{kase.case_number}' AND status is null")
          # end
          # k.save
          kase.outcome = j_status
        else
          kase.outcome = 'Judgment'
          Judgement.find_or_create_by_case_number(:case_number => kase.case_number, :notes => notes, :judgement_date => event.DateEvent)#, :is_valid => true)
        end
      end
    end
  end
  def parseInspection(case_number,inspection)
    if inspection.class == Hashie::Mash && inspection.IsComplete =~ /true/
      i = Inspection.find_or_create_by_case_number_and_inspection_date(:case_number => case_number, :inspection_date => inspection.InspectionDate, :notes => inspection.Comment)#, :is_valid => true)
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
    if action.class == Hashie::Mash && action.IsComplete =~ /true/
      if (action.Type =~ /Notice/ && action.Type =~ /Hearing/) || action.Type == 'Notice'
        Notification.create(:case_number => kase.case_number, :notified => action.Date, :notification_type => action.Type)#, :is_valid => true)
      elsif action.Type =~ /Notice/ && action.Type =~ /Reset/
        Reset.create(:case_number => kase.case_number, :reset_date => action.Date)#, :is_valid => true)
      elsif action.Type =~ /Notice/ && action.Type =~ /Compliance/
        kase.outcome = 'Closed: In Compliance'
      elsif action.Type =~ /Judgment/ && (action.Type =~ /Posting/ || action.Type =~ /Recordation/ || action.Type =~ /Notice/)
        j = Judgement.find_or_create_by_case_number(:case_number => kase.case_number, :judgement_date => action.Date, :notes => action.Type)#, :is_valid => true)
        unless j.status
          kase.outcome = 'Judgment' if kase.outcome != 'Judgment'
        end
      elsif action.Type =~ /Administrative Hearing/
        unless action.Type =~ /Notice/
         Hearing.create(:case_number => kase.case_number, :hearing_date => action.Date, :hearing_type => action.Type)#, :is_valid => true)
        end
      end
    end
  end
  def parseStatus(kase,case_status,date)
    if case_status =~ /Compliance/ 
      kase.outcome = "Closed: In Compliance"
    elsif case_status =~ /Dismiss/ || case_status =~ /dismiss/
      kase.outcome = 'Closed: Dismissed'
    elsif case_status =~ /Closed/ 
      kase.outcome = 'Closed'
    elsif case_status =~ /Guilty/
      if case_status =~ /Not Guilty/
        kase.outcome = 'Not Guilty'
      else
        kase.outcome = 'Guilty'
      end
        # j = kase.judgement
        # k = Judgement.new(:case_number => kase.case_number, :status => kase.outcome, :judgement_date => date, :notes => case_status)#, :is_valid => true)
        Judgement.create(:case_number => kase.case_number, :status => kase.outcome, :judgement_date => date, :notes => case_status)#, :is_valid => true)
        # puts "old judgement => #{j.inspect}"
        # if j && j.status.nil?
        #   invalidate_steps(kase, k)
        #   #Judgement.delete_all("case_number = '#{kase.case_number}' AND status is null")
        # end
        # k.save
    elsif case_status =~ /Judgment/ && (case_status =~ /Posting/ || case_status =~ /Notice/ || case_status =~ /Recordation/)
      j = Judgement.find_or_create_by_case_number(:case_number => kase.case_number, :judgement_date => date, :notes => case_status)#, :is_valid => true)
      unless j.status
        kase.outcome = 'Judgment' if kase.outcome != 'Judgment'
      end
    elsif case_status =~ /Judgment rescinded/
      kase.outcome = 'Judgment Rescinded' 
    elsif case_status =~ /omplaint/ && case_status =~ /eceived/
      Complaint.create(:case_number => kase.case_number, :status => 'Received', :date_received => date, :notes => case_status)#, :is_valid => true)
    end
  end

  def invalidate_steps(kase)#, bad_judgement)
    latest = kase.most_recent_status
    bad_judgement = Judgement.where(:case_number => kase.case_number, :status => nil).last if bad_judgement.nil?#latest = kase.most_recent_status if latest.nil?
    j = bad_judgement
    if  j && latest && j != latest && (j.status.nil? || j.status.length == 0)
      kase.adjudication_steps.each do |s|
        if s.date < j.date
          puts "Deleting step => #{s.inspect}"
          s.delete #update_attribute(:is_valid, false)
        end
      end
      puts "Deleting Judgement => #{j.inspect}"
      j.delete
    end
  end

  def get_incident_division_by_location(lama,location,case_number)
    division = nil
    incidents = lama.incidents_by_location(location)
    if incidents.class == Hashie::Mash
      if incidents.Number == case_number
        division = incidents.Division
        puts "location => #{location}     Class => #{incidents.class.to_s}"
      end
    elsif incidents.class == Array
      incidents.each do |incident|
        if incident.Number == case_number
          division = incident.Division
          puts "location => #{location}     Class => #{incident.class.to_s}"
        end
      end
    end
    print "case_number =>   #{case_number}    division => #{division}"
    division
  end
end
