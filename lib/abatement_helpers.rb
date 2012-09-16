module AbatementHelpers
	def match_case(abatements)
		success = 0
    	failure = 0	
		abatements.each do |row|
	      # compare each address in demo list to our address table
	      
	      date = DateTime.new
	      prev_date = date
	      row.address.cases.each do |kase|
	        date = kase.judgement.date if kase.judgement
	        if date > prev_date && date < row.date
	          row.case = kase
	          prev_date = date
	        end
	      end
	      row.case_confidence = true
	      unless row.case
	        date = DateTime.new
	        prev_date = date
	        row.address.cases.each do |kase|
	          date = kase.most_recent_step_before_abatement.date if kase.most_recent_step_before_abatement
	          if date > prev_date && date < row.date
	            row.case = kase
	            prev_date = date
	          end
	        end
	        row.case_confidence = false if row.case
	      end
	      if row.case
	      	row.save 
	      	success += 1
	      else
	      	failure += 1
	      end
	    end   

	    puts "#{abatements.first.class} => There were #{success} successful matches and #{failure} failed matches"      
	end
end