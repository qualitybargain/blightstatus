class HealthController < ApplicationController

	respond_to :html, :json
	
	def cases_incomplete
		@cases = Case.incomplete
		#Kaminari.paginate_array(@cases).page(params[:page]).per(100)
		respond_with(@cases)
	end

	def judgements_no_hearing
	end

	def hearings_no_notification
	end

	def notifications_no_inspection
	end

	def cases_orphan
		@cases = Case.orphans
		respond_with(@cases)
	end

	def orphan_steps
	end

end
