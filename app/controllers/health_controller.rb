class HealthController < ApplicationController
	before_filter :authenticate_admin!
	respond_to :html, :json
	
	def cases_incomplete
		@cases = Case.incomplete
		#Kaminari.paginate_array(@cases).page(params[:page]).per(100)
		respond_with(@cases)
	end

	def cases_orphan
		@cases = Case.orphans
		respond_with(@cases)
	end

	def cases_missing
		@cases = Case.missing
		respond_with(@cases)
	end

end
