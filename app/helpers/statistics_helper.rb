module StatisticsHelper

	def addresses_stats
		{:total => Address.count}
	end

	def cases_stats
		{:total => Case.count, :matched => Case.matched_count, :unmatched => Case.unmatched_count, :percentageMatche => Case.pct_matched}
	end

	def inspections_stats
		{:total => Inspection.count, :matched => Inspection.matched_count, :unmatched => Inspection.unmatched_count, :percentageMatched => Inspection.pct_matched,:types =>Inspection.types,:results => Inspection.results}
	end

	def notifications_stats
		{:total => Notification.count, :matched => Notification.matched_count, :unmatched => Notification.unmatched_count, :percentageMatched => Notification.pct_matched, :types => Notification.types}
	end

	def hearings_stats
		{:total => Hearing.count, :matched => Hearing.matched_count, :unmatched => Hearing.unmatched_count, :percentageMatched => Hearing.pct_matched, :status => Hearing.status}
	end

	def resets_stats
		{:total => Reset.count, :matched => Reset.matched_count, :unmatched => Reset.unmatched_count, :percentageMatched => Reset.pct_matched}
	end

	def judgements_stats
		{:total => Judgement.count, :matched => Judgement.matched_count, :unmatched => Judgement.unmatched_count, :percentageMatched => Judgement.pct_matched, :status => Judgement.status}
	end

	def maintenances_stats
		{:total => Maintenance.count, :matched => Maintenance.matched, :unmatched => Maintenance.unmatched, :percentageMatched => Maintenance.pct_matched, :program_names => Maintenance.program_names, :status => Maintenance.status}
	end

	def foreclosures_stats
		{:total => Foreclosure.count, :matched => Foreclosure.matched_count, :unmatched => Foreclosure.unmatched_count, :percentageMatched => Foreclosure.pct_matched, :status => Foreclosure.status}
	end

	def demolitions_stats
		{:total => Demolition.count, :matched => Demolition.matched_count, :unmatched => Demolition.unmatched_count, :percentageMatched => Demolition.pct_matched}
	end

end