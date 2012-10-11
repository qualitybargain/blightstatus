module LAMAHelpers
  def import_to_database(incidents, client=nil)
    l = client || LAMA.new({ :login => ENV['LAMA_EMAIL'], :pass => ENV['LAMA_PASSWORD']})

    incidents.each do |incident|
      # begin
        case_number = incident.Number
        next unless case_number # need to find a better way to deal with this ... revisit post LAMA data cleanup
        
        division = get_incident_division_by_location(l,incident.Location,case_number)

        next unless division == 'CE'
        
        # action_spawns = nil
        # judgement_spawns = nil
        # inspection_spawns = nil

        case_state = 'Open'
        case_state = 'Closed' if incident.IsClosed =~/true/
        kase = Case.find_or_create_by_case_number(:case_number => case_number, :state => case_state)
        
        puts "case => #{case_number}   status => #{incident.CurrentStatus}    date => #{incident.CurrentStatusDate}"
        orig_state = kase.state
        orig_outcome = kase.outcome
        incident_full = l.incident(case_number)
        
        #Go through all data points and pull out relevant things here
        #Inspections
        spawn_hash = {}
        inspections = incident_full.Inspections
        if inspections
          if inspections.class == Hashie::Mash
            inspections = inspections.Inspection
            if inspections.class == Array
              inspections.each do |inspection|
                i = parseInspection(case_number,inspection)          
                spawn_hash[i[:spawn_id]] = i 
              end
            end
          end
        end

        judgements = incident_full.Judgments
        if judgements
          if judgements.class == Hashie::Mash
            judgement = judgements.Judgment
            j = parseJudgement(kase,judgement)
            spawn_hash[j[:spawn_id]] = j
          end
        end
        
        #Actions
        actions = []
        if incident_full.Actions && incident_full.Actions.CodeAction
          actions = incident_full.Actions.CodeAction
          if actions
            if actions.class == Array
              actions.each do |action|
                a = parseAction(kase, action)
                spawn_hash[a[:spawn_id]] = a
              end
            else
              a = parseAction(kase, actions)
              spawn_hash[a[:spawn_id]] = a
            end     
          end      
        end

        puts "spawn_hash => #{spawn_hash.inspect}"
        #Events
        events = []
        if incident_full.Events && incident_full.Events.IncidEvent
          events = incident_full.Events.IncidEvent
        end
        if events
          if events.class == Array
            events.each do |event|
              parseEvent(kase,event,spawn_hash)          
            end
          else
            parseEvent(kase,events,spawn_hash)
          end
        end


        #Violations
        #TODO: add violations table and create front end for this 
        #Judgments - Closed
    #     case_status = incident_full.Description
    #     if (case_status =~ /Status:/ && case_status =~ /Status Date:/)
    #       case_status = case_status[((case_status =~ /Status:/) + "Status:".length) ... case_status =~ /Status Date:/].strip

    #       d = incident_full.Description
    #       d = d[d.index('Status Date:') .. -1].split(' ')
    #       d = d[2].split('/')
    #       d = DateTime.new(d[2].to_i,d[0].to_i,d[1].to_i)

    #       parseStatus(kase,case_status,d)
    #     end
        
        if kase.address.nil?
          addresses = AddressHelpers.find_address(incident.Location)
          unless addresses.empty?
            kase.address = addresses.first
          end
        end
        if !kase.accela_steps.nil? || kase.state != orig_state || kase.outcome != orig_outcome
          # invalidate_steps(kase)
          k = kase.save
        end
      # rescue StandardError => ex
      #   puts "THERE WAS AN EXCEPTION OF TYPE #{ex.class}, which told us that #{ex.message}"
      # end
    end
  end

  def parseEvent(kase,event,spawn_hash)
    case_number = kase.case_number
    if event.class == Hashie::Mash && event.IsComplete =~ /true/
      j_status = nil
      if ((event.Type =~ /Notice/ || event.Name =~ /Notice/) && (event.Type =~ /Hearing/ || event.Name =~ /Hearing/)) || (event.Type == 'Notice' || event.Name == 'Notice')
        if event.SpawnID && event.SpawnID != '-1' && spawn_hash[event.SpawnID]
          Notification.create(:case_number => kase.case_number, :notified => spawn_hash[event.SpawnID][:date], :notification_type => spawn_hash[event.SpawnID][:notes])
        else
          Notification.create(:case_number => kase.case_number, :notified => event.DateEvent, :notification_type => event.Type)
        end
      elsif event.Type =~ /Administrative Hearing/
        if event.SpawnID && event.SpawnID != -1 && spawn_hash[event.SpawnID]
          Judgement.create(:case_number => kase.case_number, :notes => spawn_hash[event.SpawnID][:notes], :status => spawn_hash[event.SpawnID][:status], :judgement_date => spawn_hash[event.SpawnID][:date])
        end
        Hearing.create(:case_number => kase.case_number, :hearing_date => event.DateEvent, :hearing_status => event.Status, :hearing_type => event.Type, :is_complete => true)#, :is_valid => true)
      elsif event.Type =~ /Input Hearing Results/
       if event.Items != nil and event.IncidEventItem != nil
         event.IncidEventItem.each do |item|
           if item.class == Hashie::Mash
             if (item.Title =~ /Reset Notice/ || item.Title =~ /Reset Hearing/) && item.IsComplete == "true"
                if event.SpawnID && event.SpawnID != -1 && spawn_hash[event.SpawnID]
                  Reset.create(:case_number => kase.case_number, :reset_date => spawn_hash[event.SpawnID][:date])
                else
                  Reset.create(:case_number => kase.case_number, :reset_date => item.DateCompleted)
                end
             end
           end
         end
       end
      elsif event.Type =~ /Inspection/ || event.Name =~ /Inspection/ || event.Type =~ /Reinspection/ || event.Name =~ /Reinspection/
        if event.SpawnID && event.SpawnID != '-1' && spawn_hash[event.SpawnID]
          i = Inspection.create(:case_number => kase.case_number, :inspection_date => spawn_hash[event.SpawnID][:date], :notes => spawn_hash[event.SpawnID][:notes])
        else
          i = Inspection.create(:case_number => kase.case_number, :inspection_date => event.DateEvent, :notes => event.Status, :inspection_type => event.Type)
        end
      elsif event.Type =~ /Complaint Received/ || event.Name =~ /Complaint Received/
       Complaint.create(:case_number => kase.case_number, :date_received => event.DateEvent, :status => event.Status)
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
          #Hearing.create(:case_number => kase.case_number, :hearing_date => event.DateEvent, :hearing_status => j_status)

          Judgement.where(:case_number => kase.case_number, :status => nil).destroy_all
          
          if event.SpawnID && event.SpawnID != '-1' && spawn_hash[event.SpawnID]
            Judgement.create(:case_number => kase.case_number, :notes => spawn_hash[event.SpawnID][:notes], :status => spawn_hash[event.SpawnID][:status], :judgement_date => spawn_hash[event.SpawnID][:date])
          else
            Judgement.find_or_create_by_case_number(:case_number => kase.case_number, :notes => notes, :status => j_status, :judgement_date => event.DateEvent)
          end
          kase.outcome = j_status
        else
          kase.outcome = 'Judgment'
          if event.SpawnID && event.SpawnID != '-1' && spawn_hash[event.SpawnID]
            Judgement.create(:case_number => kase.case_number, :notes => spawn_hash[event.SpawnID][:notes], :judgement_date => spawn_hash[event.SpawnID][:date])
          else
            Judgement.find_or_create_by_case_number(:case_number => kase.case_number, :notes => notes, :judgement_date => event.DateEvent)
          end
        end
      end
    elsif event.class == Hashie::Mash && event.IsComplete =~ /false/
      last_inspection = kase.last_inspection
      last_hearing = kase.last_hearing
      h = Hearing.new(:case_number => kase.case_number, :hearing_date => event.DateEvent, :hearing_status => event.Status, :hearing_type => event.Type, :is_complete => false)
      h.save if kase.judgement.nil? && last_inspection && h.date > last_inspection.date && (last_hearing.nil? || ((last_hearing && h.date > last_hearing.date) && (last_inspection > last_hearing.date)))      
    end
  end
  def parseInspection(case_number,inspection)
    inspection_spawn = nil
    if inspection.class == Hashie::Mash && inspection.IsComplete =~ /true/
      #i = Inspection.find_or_create_by_case_number_and_inspection_date(:case_number => case_number, :inspection_date => inspection.InspectionDate, :notes => inspection.Comment)
      inspection_spawn = {:spawn_id => inspection.ID, :date => inspection.InspectionDate, :notes => inspection.Comment, :step => Inspection.to_s, :spawn_type => Inspection.to_s, :findings => {}}
      finding = {}#Hash.new
      if inspection.Findings != nil && inspection.Findings.InspectionFinding != nil
        inspection.Findings.InspectionFinding.each do |finding|
          if finding.class == Hashie::Mash
            if finding.Finding && finding.Finding.length > 0
              inspection_spawn[:findings][finding.ID] = {:finding_id => finding.ID, :finding => finding.Finding, :label => finding.Label}#i.inspection_findings.create(:finding => finding.Finding, :label => finding.Label)
            end
          end
        end
      end
    end
    inspection_spawn
  end
  def parseAction(kase,action)
    action_spawn = nil
    if action.class == Hashie::Mash && action.IsComplete =~ /true/
      action_spawn = {:spawn_id => action.ID, :date => action.Date, :notes => action.Type, :spawn_type => "Action"}
      if (action.Type =~ /Notice/ && action.Type =~ /Hearing/) || action.Type == 'Notice'
        #Notification.create(:case_number => kase.case_number, :notified => action.Date, :notification_type => action.Type)
        action_spawn[:step] = Notification.to_s
      elsif action.Type =~ /Notice/ && action.Type =~ /Reset/
        action_spawn[:step] = Reset.to_s
        #Reset.create(:case_number => kase.case_number, :reset_date => action.Date)
      elsif action.Type =~ /Judgment/ && (action.Type =~ /Posting/ || action.Type =~ /Recordation/ || action.Type =~ /Notice/)
        action_spawn[:step] = Judgement.to_s
      elsif action.Type =~ /Notice/ && action.Type =~ /Compliance/
        kase.outcome = 'Closed: In Compliance'
      end
      #elsif action.Type =~ /Set/ && action.Type =~ /Hearing/ && action.Type =~ /Date/
        # action_spawn[:step] = 'Set Hearing Date' 
      # elsif action.Type =~ /Administrative Hearing/
      #   unless action.Type =~ /Notice/
      #    Hearing.create(:case_number => kase.case_number, :hearing_date => action.Date, :hearing_type => action.Type)
      #   end
      # end
    end
    return nil unless action_spawn[:step]
    action_spawn
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
        Judgement.create(:case_number => kase.case_number, :status => kase.outcome, :judgement_date => date, :notes => case_status)
    elsif case_status =~ /Judgment/ && (case_status =~ /Posting/ || case_status =~ /Notice/ || case_status =~ /Recordation/)
      j = Judgement.find_or_create_by_case_number(:case_number => kase.case_number, :judgement_date => date, :notes => case_status)
      unless j.status
        kase.outcome = 'Judgment' if kase.outcome != 'Judgment'
      end
    elsif case_status =~ /Judgment rescinded/
      kase.outcome = 'Judgment Rescinded' 
    elsif case_status =~ /omplaint/ && case_status =~ /eceived/
      Complaint.create(:case_number => kase.case_number, :status => 'Received', :date_received => date, :notes => case_status)
    end
  end

  def invalidate_steps(kase)
    latest = kase.most_recent_status
    
    j = Judgement.where(:case_number => kase.case_number, :status => nil).last
    if  j && latest && j != latest && (j.status.nil? || j.status.length == 0)
      kase.adjudication_steps.each do |s|
        s.destroy if s.date < j.date
      end
      j.destroy
    end

    j = kase.judgement
    if  j && latest && j != latest && !j.status.nil? && (j.status =~ /Rescinded/).nil?
      kase.adjudication_steps.each do |s|
        if s.date > j.date
          s.destroy
        end
      end
    end
    kase.save
  end

  def get_incident_division_by_location(lama,location,case_number)
    division = nil
    begin
      incidents = lama.incidents_by_location(location)
      if incidents.class == Hashie::Mash
        division = incidents.Division if incidents.Number == case_number
      elsif incidents.class == Array
        incidents.each do |incident|
          division = incident.Division if incident.Number == case_number
        end
      end
    rescue StandardError => ex
      puts "There was an error of type #{ex.class}, with a message of #{ex.message}"
    end
    division
  end

  def parseJudgement(kase,judgement)
    judgement_spawn = nil
    if judgement.class == Hashie::Mash
      j_status = judgement.Status.downcase if judgement.Status
      date = judgement.D_Court if judgement.D_Court
      id = judgement.ID if judgement.ID
    
      return judgement_spawn if j_status =~ /pending/

      if j_status =~ /dismiss/
        j = 'Dismissed'
        kase.outcome = "Closed: Dismissed"
      elsif j_status =~ /closed/
        j = 'Closed'
        kase.outcome = "Closed"
      elsif j_status =~ /guilty/
        if j_status =~ /not guilty/
          j = 'Not Guilty'
        else
          j = 'Guilty'
        end
        kase.outcome = j        
      elsif j_status =~ /rescinded/
          j = 'Rescinded'
          kase.outcome = 'Judgment Rescinded' 
      end
      j_status = judgement.Status unless judgement.Status.nil?  
      #Judgement.create(:case_number => kase.case_number, :status => j, :judgement_date => date, :notes => j_status)      
      judgement_spawn = {:spawn_id => judgement.ID, :status => j, :date => date, :notes => j_status, :spawn_type => Judgement.to_s, :step => Judgement.to_s}
    end
    judgement_spawn
  end
end
