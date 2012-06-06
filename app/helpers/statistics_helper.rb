module StatisticsHelper

	def addresses
		{:total => Address.count}
	end

	def cases
		{:total => Case.count, :matched => Case.matched_count, :unmathed => Case.unmatched_count, :percentageMatche => Case.pct_matched}
	end

	def inspections
		{:total => Inspection.count, :matched => Inspection.matched_count, :unmatched => Inspection.unmatched_count, :percentageMatched => Inspection.pct_matched,:types =>Inspection.types,:results => Inspection.results}
	end

	def notifications
		{:total => Notification.count, :matched => Notification.matched_count, :unmatched => Notification.unmatched_count, :percentageMatched => Notification.pct_matched, :types => Notification.types}
	end

	def hearings
		{:total => Hearing.count, :matched => Hearing.matched_count, :unmatched => Hearing.unmatched_count, :percentageMatched => Hearing.pct_matched, :status => Hearing.status}
	end

	def resets
		{:total => Reset.count, :matched => Reset.matched_count, :unmatched => Reset.unmatched_count, :percentageMatched => Reset.pct_matched}
	end

	def judgements
		{:total => Judgement.count, :matched => Judgement.matched_count, :unmatched => Judgement.unmatched_count, :percentageMatched => Judgement.pct_matched, :status => Judgement.status}
	end

	def maintenances
		{:total => Maintenance.count, :matched => Maintenance.matched, :unmatched => Maintenance.unmatched, :percentageMatched => Maintenance.pct_matched, :program_names => Maintenance.program_names, :status => Maintenance.status}
	end

	def foreclosures
		{:total => Foreclosure.count, :matched => Foreclosure.matched_count, :unmatched => Foreclosure.unmatched_count, :percentageMatched => Foreclosure.pct_matched, :status => Foreclosure.status}
	end

	def demolitions
		{:total => Demolition.count, :matched => Demolition.matched_count, :unmatched => Demolition.unmatched_count, :percentageMatched => Demolition.pct_matched}
	end

end